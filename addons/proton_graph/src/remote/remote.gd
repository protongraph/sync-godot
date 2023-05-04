@tool
extends RefCounted


const CONFIG_FILE := "../../../config.cfg"


signal connection_established
signal connection_lost
signal data_received


var _socket: WebSocketPeer
var _buffer := {}


func connect_to_server() -> void:
	close_connection()

	# Fetch address and port from the config file
	var file := ConfigFile.new()
	file.load(CONFIG_FILE)

	var address: String = file.get_value("host", "address", "127.0.0.1")
	var port: int = file.get_value("host", "port", 9123)

	# Connect to the ProtonGraph application
	_socket = WebSocketPeer.new()
	var url := "ws://" + address + ":" + str(port)
	var err := _socket.connect_to_url(url)

	if err == OK:
		connection_established.emit()
	else:
		printerr("Could not connect to ", url)
		_socket = null


func close_connection() -> void:
	if _socket:
		_socket.close()
		_socket = null
		connection_lost.emit()


func poll() -> void:
	if not _socket:
		return

	_socket.poll()

	match _socket.get_ready_state():
		WebSocketPeer.STATE_OPEN:
			while _socket.get_available_packet_count():
				_handle_incomming_packet(_socket.get_packet())

		WebSocketPeer.STATE_CLOSED:
			var code = _socket.get_close_code()
			var reason = _socket.get_close_reason()
			_socket = null
			print("WebSocket closed with code: %d, reason %s. Clean: %s" % [code, reason, code != -1])
			connection_lost.emit()


# This method splits the data into smaller packets before sending them on the
# websocket (Godot limits WebSocket packets size to 64kb by default).
# Custom packet format:
# {0: stream_id, 1: chunk_id, 2: total_chunk_count, 2: data_chunk}
func send_data(data: Dictionary) -> void:
	if not is_connected_to_server():
		return

	var stream_id: int = randi()
	var msg: String = var_to_str(data)

	# Calculate how many & will be sent, leave some margin for the extra
	# caracters overhead (brackets, comas, digits used for the chunk id and
	# total count and so on) this probably won't take more than 200 chars.
	var chunk_size: int = (64 * 1024) - 200
	var total_chunks_count: int = msg.length() / chunk_size + 1

	for chunk_id in total_chunks_count:
		var data_chunk = msg.substr(chunk_id * chunk_size, chunk_size)
		var packet := {
			0: stream_id,
			1: chunk_id,
			2: total_chunks_count,
			3: data_chunk
		}
		var buffer := var_to_str(packet).to_utf8_buffer()
		print_verbose("Sending packet: ", buffer.size() / 1024.0, "kb")
		var err = _socket.put_packet(buffer)
		if err != OK:
			printerr("Code ", err, " while sending packet to server ", _socket.get_connected_host())


func is_connected_to_server() -> bool:
	if not _socket:
		return false

	return _socket.get_ready_state() == WebSocketPeer.STATE_OPEN


# Accumulate the socket packets and merge them once every chunk have been received.
func _handle_incomming_packet(packet: PackedByteArray) -> void:
	var string: String = packet.get_string_from_utf8()
	var data: Dictionary = str_to_var(string)
	var stream_id := data[0] as int
	var chunk_id := data[1] as int
	var total_chunks_count := data[2] as int
	var data_chunk : String = data[3]

	if not stream_id in _buffer:
		_buffer[stream_id] = {}

	_buffer[stream_id][chunk_id] = data_chunk

	# If all the packets are there, merge them into the final data.
	if _buffer[stream_id].size() == total_chunks_count:
		var keys: Array = _buffer[stream_id].keys()
		keys.sort()

		var final_string := ""
		for key in keys:
			final_string += _buffer[stream_id][key]

		var merged_data = str_to_var(final_string)
		data_received.emit(merged_data)
