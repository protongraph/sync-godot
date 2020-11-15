tool
extends Node


var _client
var _client_script = load(_get_current_folder() + "/client.gd")
var _queue := []


func _ready():
	_start_client()


func rebuild(template_path: String, inspector: Array, inputs: Array) -> void:
	if not _client.is_connected_to_server():
		_start_client()
		_queue.append([template_path, inspector, inputs])
		return
	
	var msg := {}
	msg["path"] = template_path
	_client.send(msg)


func _start_client() -> void:
	if not _client:
		_client = _client_script.new()
		add_child(_client)
		_client.connect("connection_etablished", self, "_on_connection_etablished")
		_client.connect("data_received", self, "_on_data_received")
		
	_client.start()


func _get_current_folder() -> String:
	var script: Script = get_script()
	var path: String = script.get_path()
	return path.get_base_dir()


# Client just connected to the server, send the queued requests
func _on_connection_etablished() -> void:
	# Don't use a while(pop_front) here to prevent an infinite loop if the
	# server is disconnected before we empty the queue.
	var count = _queue.size()
	for i in count:
		var args = _queue.pop_front()
		rebuild(args[0], args[1], args[2])


func _on_data_received(data: String) -> void:
	var json = JSON.parse(data)
	if json.error != OK:
		print("Data was not a valid json object")
		print("error ", json.error, " ", json.error_string, " at ", json.error_line)
		return
	
	var msg: Dictionary = json.result
	if not msg.has("type"):
		return
	
	match msg["type"]:
		"build_complete":
			_on_build_completed(msg["data"])
		_:
			print("Unsupported message ", msg["type"])
			print(msg)


func _on_build_completed(data) -> void:
	print("Build completed ", data)
	var res := []
	
