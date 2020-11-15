tool
extends Spatial


signal template_path_changed


export(String, FILE, "*.cgraph") var template_file
export var paused := false

var _initialized := false
var _inputs: Spatial
var _outputs: Spatial
var _exposed_variables := {}
var _protocol
var _protocol_script = load(_get_current_folder() + "/network/protocol.gd")
var _input_manager_script = load(_get_current_folder() + "/input_manager.gd")


func _ready():
	if _initialized:
		return
	
	_inputs = _get_or_create_root("Inputs")
	_outputs = _get_or_create_root("Outputs")
	
	if Engine.is_editor_hint():
		_inputs.connect("input_changed", self, "_on_input_changed")
		_protocol = _protocol_script.new()
		add_child(_protocol)
	else:
		# The game is running, remove the inputs node as they will get in the
		# way and waste resources.
		_inputs.queue_free()
	
	_initialized = true


# Template files can expose properties to the inspector. 
# This requires to override _get and _set as well.
func _get_property_list() -> Array:
	var res := []
	
	res.append({
		name = "Remote Status",
		type = TYPE_OBJECT,
		hint_string =  "ProtonGraphRemoteStatus",
	})
	
	for name in _exposed_variables.keys():
		var dict := {
			"name": name,
			"type": _exposed_variables[name]["type"],
		}
		if _exposed_variables[name].has("hint"):
			dict["hint"] = _exposed_variables[name]["hint"]
		if _exposed_variables[name].has("hint_string"):
			dict["hint_string"] = _exposed_variables[name]["hint_string"]
		res.append(dict)

	return res


func _get(property):
	if _exposed_variables.has(property):
		if _exposed_variables[property].has("value"):
			return _exposed_variables[property]["value"]


func _set(property, value): # overridden
	if property.begins_with("Template/"):
		if _exposed_variables.has(property):
			_exposed_variables[property]["value"] = value
			rebuild()
		else:
			# This happens when loading the scene, don't regenerate here as it will happen again
			# in _enter_tree
			_exposed_variables[property] = {"value": value}

			if value is float:
				_exposed_variables[property]["type"] = TYPE_REAL
			elif value is String:
				_exposed_variables[property]["type"] = TYPE_STRING
			elif value is Vector3:
				_exposed_variables[property]["type"] = TYPE_VECTOR3
			elif value is bool:
				_exposed_variables[property]["type"] = TYPE_BOOL
			elif value is Curve:
				_exposed_variables[property]["type"] = TYPE_OBJECT
				_exposed_variables[property]["hint"] = PROPERTY_HINT_RESOURCE_TYPE
				_exposed_variables[property]["hint_string"] = "Curve"

			property_list_changed_notify()
		return true
	return false


func update_exposed_variables(variables: Array) -> void:
	var old = _exposed_variables
	_exposed_variables = {}

	for v in variables:
		if _exposed_variables.has(v.name):
			continue

		var value = old[v.name]["value"] if old.has(v.name) else v["default_value"]
		_exposed_variables[v.name] = {
			"type": v["type"],
			"value": value,
		}
		if v.has("hint"):
			_exposed_variables[v.name]["hint"] = v["hint"]
		if v.has("hint_string"):
			_exposed_variables[v.name]["hint_string"] = v["hint_string"]
	property_list_changed_notify()



# Clear the scene tree from everything returned by the template generation.
func clear_output() -> void:
	if not _outputs:
		_outputs = _get_or_create_root("Outputs")

	for c in _outputs.get_children():
		_outputs.remove_child(c)
		c.queue_free()


# Serialize all the inputs and inspector data, then request the standalone app
# to generate a result.
func rebuild() -> void:
	if not Engine.is_editor_hint() or paused:
		return

	_protocol.rebuild(template_file)


func display_results(nodes: Array) -> void:
	if not nodes or nodes.size() == 0:
		return

	clear_output()
	var owner = get_tree().get_edited_scene_root()

	for node in nodes:
		if not node:
			continue
		_outputs.add_child(node)
		node.set_owner(owner)
		_set_children_owner(node, owner)


func get_input(name: String) -> Node:
	if not _inputs:
		_inputs = _get_or_create_root("Inputs")
	
	if _inputs.has_node(name):
		return _inputs.get_node(name)
	
	return null


func _get_or_create_root(name: String) -> Node:
	if has_node(name):
		return get_node(name)

	var root = Spatial.new()
	if name == "Inputs":
		root.set_script(_input_manager_script)

	root.set_name(name)
	add_child(root)
	if get_tree():
		root.set_owner(get_tree().get_edited_scene_root())
	else:
		root.set_owner(self)
	
	return root


func _get_current_folder() -> String:
	var script: Script = get_script()
	var path: String = script.get_path()
	return path.get_base_dir()


func _set_children_owner(node, owner) -> void:
	for c in node.get_children():
		c.set_owner(owner)
		_set_children_owner(c, owner)


func _on_input_changed(_node) -> void:
	rebuild()
