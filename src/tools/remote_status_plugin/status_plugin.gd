extends EditorInspectorPlugin

# Displays a control panel in the inspector to monitor the connection status
# with the standalone app and let the user manually force the generation if
# needed.

var _root := _get_root_folder()
var proton_graph_script = load(_root + "/src/proton_graph.gd")
var status_panel = load(_root + "/src/tools/remote_status_plugin/status_editor.gd")


func can_handle(object):
	return object is proton_graph_script


func parse_property(object, type, path, hint, hint_text, usage):
	if type == TYPE_OBJECT and hint_text == "ProtonGraphRemoteStatus":
		var property_editor = status_panel.new()
		property_editor.set_node(object)
		add_property_editor(path, property_editor)
		return true
	return false


func _get_root_folder() -> String:
	var script: Script = get_script()
	var path: String = script.get_path().get_base_dir()
	var folders = path.right(6) # Remove the res://
	var tokens = folders.split('/')
	return "res://" + tokens[0] + "/" + tokens[1]
