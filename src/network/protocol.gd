tool
extends Node


signal build_completed


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
	msg["command"] = "build"
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


func _on_data_received(msg: Dictionary) -> void:
	if not msg.has("type"):
		return
	
	match msg["type"]:
		"build_completed":
			_on_build_completed(msg["data"])
		_:
			print("Unsupported message ", msg["type"])
			print(msg)


func _on_build_completed(data: Array) -> void:
	var res := []
	for dict in data:
		res.append(_deserialize_node_tree(dict))
	
	emit_signal("build_completed", res)


func _deserialize_node_tree(data: Dictionary) -> Node:
	var res
	match data["type"]:
		"node_3d":
			res = _deserialize_node(data["data"])
		"mesh":
			res = _deserialize_mesh(data["data"])
	
	if data.has("children"):
		for child in data["children"]:
			res.add_child(_deserialize_node_tree(child))
	
	return res


func _deserialize_node(data: Dictionary) -> Position3D:
	var node = Position3D.new()
	node.name = data["name"]
	node.transform = _extract_transform(data)
	return node


func _deserialize_mesh(data: Dictionary) -> MeshInstance:
	var mi = MeshInstance.new()
	mi.transform = _extract_transform(data)
	
	var mesh = ArrayMesh.new()
	for i in data["mesh"].keys():
		var source = data["mesh"][i]
		var surface_arrays = []
		surface_arrays.resize(Mesh.ARRAY_MAX)
		surface_arrays[Mesh.ARRAY_VERTEX] = _to_pool(source[Mesh.ARRAY_VERTEX])
		surface_arrays[Mesh.ARRAY_NORMAL] = _to_pool(source[Mesh.ARRAY_NORMAL])
		surface_arrays[Mesh.ARRAY_TEX_UV] = _to_pool(source[Mesh.ARRAY_TEX_UV])
		surface_arrays[Mesh.ARRAY_INDEX] = PoolIntArray(source[Mesh.ARRAY_INDEX])
	
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_arrays)
	
	mi.mesh = mesh
	return mi


func _to_pool(array: Array):
	var tmp = []
	for vec in array:
		tmp.append(_extract_vector(vec))

	if tmp[0] is Vector2:
		return PoolVector2Array(tmp)

	return PoolVector3Array(tmp)


func _extract_transform(data: Dictionary) -> Transform:
	var t = Transform()
	if data.has("pos"):
		t.origin = _extract_vector(data["pos"])
	
	if data.has("basis"):
		var basis: Array = data["basis"]
		t.basis.x = _extract_vector(basis[0])
		t.basis.y = _extract_vector(basis[1])
		t.basis.z = _extract_vector(basis[2])
	
	return t


func _extract_vector(data: Array) -> Vector3:
	var v = null
	if data.size() == 3:
		v = Vector3.ZERO
		v.x = data[0]
		v.y = data[1]
		v.z = data[2]
	
	elif data.size() == 2:
		v = Vector2.ZERO
		v.x = data[0]
		v.y = data[1]
	
	return v
