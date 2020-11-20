tool
extends Spatial


signal template_path_changed


export(String, FILE, "*.cgraph") var template_file setget _set_template_file
export var paused := false

var _initialized := false
var _inputs: Spatial
var _outputs: Spatial
var _exposed_variables := {}
var _protocol

var _protocol_script = load(_get_current_folder() + "/network/protocol.gd")
var _input_manager_script = load(_get_current_folder() + "/input_manager.gd")
var _node_util = load(_get_current_folder() + '/common/node_util.gd')
var _dict_util = load(_get_current_folder() + '/common/dict_util.gd')
var _inspector_util = load(_get_current_folder() + '/common/inspector_util.gd')


func _ready():
	if _initialized:
		return
	
	_inputs = _get_or_create_root("Inputs")
	_outputs = _get_or_create_root("Outputs")
	
	if Engine.is_editor_hint():
		_inputs.connect("input_changed", self, "_on_input_changed")
		_protocol = _protocol_script.new()
		add_child(_protocol)
		_protocol.connect("build_completed", self, "_on_build_completed")
		_load_template(template_file)
	else:
		# The game is running, remove the inputs node as they will get in the
		# way and waste resources.
		_inputs.queue_free()
	
	_initialized = true


# Template files can expose properties to the inspector. 
# This requires to override _get and _set as well.
func _get_property_list() -> Array:
	var res := []
	
	# Used to display the connection UI in the inspector.
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
	if not property.begins_with("Template/"):
		return false
	
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


# Removes all the previous build results from the local scene tree.
func clear_output() -> void:
	if not _outputs:
		_outputs = _get_or_create_root("Outputs")

	for c in _outputs.get_children():
		_outputs.remove_child(c)
		c.queue_free()


# Serialize all the inputs and inspector data, then request the standalone app
# to generate a result.
func rebuild() -> void:
	if not Engine.is_editor_hint() or not _protocol or paused:
		return
	var global_path = ProjectSettings.globalize_path(template_file)
	var inspector_values = _inspector_util.serialize(self)
	var inputs = _node_util.serialize_all(_inputs.get_children())
	_protocol.rebuild(global_path, inspector_values, inputs)


# Load the template file and search for inputs or inspector properties to 
# expose them to the scene tree or to the inspector.
func _load_template(path) -> void:
	if not path or path == "":
		return

	# Open the file and read the contents
	var file = File.new()
	file.open(path, File.READ)
	var json = JSON.parse(file.get_as_text())
	if not json or not json.result:
		print("Failed to parse the template file")
		return	# Template file is either empty or not a valid Json. Ignore

	# Abort if the file doesn't have node data
	var graph: Dictionary = _dict_util.fix_types(json.result)
	if not graph.has("nodes"):
		return

	# For each node found in the template file
	for node_data in graph["nodes"]:
		if not node_data.has("type"):
			continue
		
		if not _inspector_util.is_property(node_data["type"]):
			continue
		
		var n = "Template/" + node_data["editor"]["inputs"][0]["value"]
		var v = node_data["editor"]["inputs"][1]["value"]
		
		if not _exposed_variables.has(n):
			_exposed_variables[n] = {
				"default_value": v,
				"type": _inspector_util.to_variant_type(v)
			}

	if graph.has("inspector"):
		for var_name in graph["inspector"].keys():
			if not _exposed_variables.has(var_name):
				continue
			
			if _exposed_variables[var_name].has("value"):
				continue # Don't override the user proivded scene value
			
			_exposed_variables[var_name]["value"] = graph["inspector"][var_name]
	
	property_list_changed_notify()


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


func _set_template_file(path: String) -> void:
	template_file = path
	_load_template(path)


func _on_input_changed(_node) -> void:
	rebuild()


func _on_build_completed(nodes: Array) -> void:
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
