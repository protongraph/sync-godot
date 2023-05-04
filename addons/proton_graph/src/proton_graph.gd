@tool
extends Node3D


signal build_completed


const REMOTE := preload("./remote/remote.gd")
const GRAPH_PARSER := preload("./common/graph_parser.gd")
const PARAMETER_PREFIX := "graph_parameters/"


@export_global_file("*.tpgn") var graph_file: String = "":
	set(val):
		if graph_file != val:
			graph_file = val
			reload_node_graph()

var _remote := REMOTE.new()
var _parser := GRAPH_PARSER.new()
var _graph_parameters := {} # Node graph pinned variables and their current value.
var _result: Node3D
var _current_result_version := 0
var _is_ready := false


func _ready():
	_remote.data_received.connect(_on_data_received)
	_remote.connect_to_server()
	_is_ready = true
	_result = get_node_or_null("Output")


func _process(delta):
	_remote.poll()


func _get_property_list() -> Array:
	var res: Array[Dictionary] = []

	# Show the remote status inspector plugin.
	res.append({
		"name": "control_panel",
		"type": TYPE_OBJECT,
		"hint_string": "ProtonGraphRemote",
	})

	# Append the graph variables, they'll get sent along the rebuild request.
	for variable_name in _graph_parameters.keys():
		var value = _graph_parameters[variable_name]
		var type := typeof(value)

		var dict := {
			"name": "graph_parameters/" + variable_name,
			"type": type,
			"value": value,
		}
		res.append(dict)

	return res


func _get(property: StringName) -> Variant:
	if property.begins_with(PARAMETER_PREFIX):
		var pname = property.trim_prefix(PARAMETER_PREFIX)
		return _graph_parameters[pname]
	return null


func _set(property: StringName, value: Variant) -> bool:
	if property.begins_with(PARAMETER_PREFIX):
		var pname = property.trim_prefix(PARAMETER_PREFIX)
		_graph_parameters[pname] = value
		rebuild.call_deferred() # A graph parameter was changed, request a rebuild.
		return true
	return false


func rebuild() -> void:
	if not _is_ready or not _remote.is_connected_to_server():
		return # Not fully initialized yet, abort

	var msg := {
		"type": "build_request",
		"id": _current_result_version + 1,
		"graph_path": graph_file,
		"parameters": var_to_str(_graph_parameters),
		"inputs": {},
	}
	_remote.send_data(msg)


func reload_node_graph() -> void:
	# Save current values
	var backup := _graph_parameters.duplicate(true)

	# Retrieve parameter list and default values.
	_parser.parse(graph_file)
	_graph_parameters = _parser.get_pinned_variables()

	# Restore user values if any.
	for pname in _graph_parameters.keys():
		if pname in backup:
			_graph_parameters[pname] = backup[pname]

	# Force inspector to rebuild its UI.
	notify_property_list_changed()


func _on_data_received(data: Dictionary) -> void:
	if not "scene_tree" in data or not "id" in data:
		printerr("Invalid packet format received: ", data)
		return

	var version := data["id"] as int
	if version <= _current_result_version:
		return # Old build that arrived late, ignore.

	var scene := data["scene_tree"] as PackedScene
	if not scene:
		printerr("Could not find a PackedScene.")
		return

	if not scene.can_instantiate():
		printerr("Corrupted PackedScene received.")
		return

	# Put the final nodes in the tree
	_current_result_version = version
	var result: Node3D = scene.instantiate()
	add_child(result)

	# Remove the old nodes
	if is_instance_valid(_result):
		remove_child(_result)
		_result.queue_free()

	_result = result
	_result.name = "Output"

	# Update the node owners to show them in the tree.
	var edited_scene_root := get_tree().get_edited_scene_root()
	result.set_owner(edited_scene_root)
	for c in result.get_children():
		c.set_owner(edited_scene_root)

	build_completed.emit()
