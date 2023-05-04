@tool
extends EditorInspectorPlugin

# Displays a control panel in the inspector to monitor the connection status
# with the standalone app and let the user manually force the generation if
# needed.


const PROTON_GRAPH := preload("../../proton_graph.gd")
const REMOTE_EDITOR_PROPERTY := preload("./remote_editor_property.gd")


func _can_handle(node):
	return node is PROTON_GRAPH


func _parse_property(object: Object, type, name: String, hint_type: PropertyHint, hint_string: String, usage_flags: PropertyUsageFlags, wide: bool):
	if type == TYPE_OBJECT and hint_string == "ProtonGraphRemote":
		var property_editor = REMOTE_EDITOR_PROPERTY.new()
		property_editor.set_node(object)
		add_property_editor(name, property_editor)
		return true
	return false


func _get_root_folder() -> String:
	var script: Script = get_script()
	var path: String = script.get_path().get_base_dir()
	var folders = path.right(6) # Remove the res://
	var tokens = folders.split('/')
	return "res://" + tokens[0] + "/" + tokens[1]
