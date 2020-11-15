tool
extends EditorPlugin


# ProtonGraph is a node based tool for procedural content generation.
# This addons takes away the burden of exporting and importing the results
# from the standalone software and directly syncs the results to the editor.
#
# This means you need to run the standalone application alongside the Godot
# engine when using this plugin. If you don't, nothing will happen and you
# should see an error warning in the inspector panel.


# TODOs
# + Make a custom gizmo to override the default spatial one so people can't
#   move the Inputs and Outputs nodes.


var status_inspector_plugin: EditorInspectorPlugin = load(
	_get_current_folder() + 
	"/src/tools/remote_status_plugin/status_plugin.gd").new()


func _enter_tree() -> void:
	var root = _get_current_folder()
	add_inspector_plugin(status_inspector_plugin)
	add_custom_type(
		"ProtonGraph", 
		"Spatial",
		load(root + "/src/proton_graph.gd"),
		load(root + "/icons/proton_graph.svg")
	)


func _exit_tree():
	remove_custom_type("ProtonGraph")
	remove_inspector_plugin(status_inspector_plugin)


# Workaround to get the root folder of the addon, so we don't rely on hardcoded
# paths to "res://addons/sync-godot". There's always someone not paying
# attention when downloading a zip from github and ends up with a folder
# named "sync-godot-master" or something else. 
func _get_current_folder() -> String:
	var script: Script = get_script()
	var path: String = script.get_path()
	return path.get_base_dir()
