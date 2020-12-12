tool
extends Node


signal data_received
signal connection_etablished
signal connection_closed


var _ws := WebSocketClient.new()
var _url := "ws://127.0.0.1"
var _port := -1 
var _retry_delay := 2.0
var _retry_timer := Timer.new()
var _queue := []
var _is_connected := false
var _dict_util = load(_get_current_folder() + "/../common/dict_util.gd")
var _incoming = {}


func _ready():
	_retry_timer.autostart = false
	_retry_timer.one_shot = true
	add_child(_retry_timer)
	
	_retry_timer.connect("timeout", self, "_try_to_connect")
	_ws.connect("connection_error", self, "_on_connection_error")
	_ws.connect("connection_established", self, "_on_connection_etablished")
	_ws.connect("connection_closed", self, "_on_connection_closed")
	_ws.connect("data_received", self, "_on_data_received")
	
	_port = 434743 # TODO: Get the port from the project settings
	_url += ":" + String(_port)


func _process(_delta: float) -> void:
	_ws.poll()


func start():
	print("Attempting to connect to ", _url)
	stop()
	_try_to_connect()


func stop() -> void:
	_ws.disconnect_from_host()


func send(data: Dictionary) -> void:
	if _is_connected:
		var msg = JSON.print(data)
		var error = _ws.get_peer(1).put_packet(msg.to_utf8())
		if error != OK:
			print("Error ", error, " - Could not send ", msg)
	else:
		_queue.append(data)


func is_connected_to_server() -> bool:
	return _is_connected


func _try_to_connect() -> void:
	var error = _ws.connect_to_url(_url)
	if error != OK:
		print("Connection failed: ", error)
		_retry_timer.start(_retry_delay)


func _get_current_folder() -> String:
	var script: Script = get_script()
	var path: String = script.get_path()
	return path.get_base_dir()


func _on_connection_error() -> void:
	print("Connection error to the server")
	_is_connected = false


func _on_connection_etablished(protocol: String) -> void:
	print("Connection etablished ", protocol)
	emit_signal("connection_etablished")
	_is_connected = true
	
	for msg in _queue:
		send(msg)
	_queue = []


func _on_connection_closed(_clean_close := false) -> void:
	_is_connected = false
	emit_signal("connection_closed")


func _on_data_received() -> void:
	var packet: PoolByteArray = _ws.get_peer(1).get_packet()
	var string = packet.get_string_from_utf8()
	
	var json = JSON.parse(string)
	if json.error != OK:
		print("Data was not a valid json object")
		print("error ", json.error, " ", json.error_string, " at ", json.error_line)
		return
	
	var data = _dict_util.fix_types(json.result)
	var id = int(data[0])
	var chunk_id = int(data[1])
	var total_chunks = int(data[2])
	var chunk = data[3]
	
	if not id in _incoming:
		_incoming[id] = {}
	
	_incoming[id][chunk_id] = chunk
	if _incoming[id].size() == total_chunks:
		_decode(id)


func _decode(id: int) -> void:
	var keys: Array = _incoming[id].keys()
	keys.sort()
	
	var string = ""
	for chunk_id in keys:
		string += _incoming[id][chunk_id]
	
	var json = JSON.parse(string)
	if json.error != OK:
		print("Data was not a valid json object")
		print("error ", json.error, " ", json.error_string, " at ", json.error_line)
		return
	
	var data = _dict_util.fix_types(json.result)
	emit_signal("data_received", data)
