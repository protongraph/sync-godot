@tool
extends EditorPlugin


const REMOTE_INSPECTOR_PLUGIN = preload("./src/remote/inspector_plugin/remote_inspector_plugin.gd")


var _remote_status_inspector_plugin: EditorInspectorPlugin


func get_name():
	return "ProtonGraph"


func _enter_tree():
	_remote_status_inspector_plugin = REMOTE_INSPECTOR_PLUGIN.new()
	add_inspector_plugin(_remote_status_inspector_plugin)

	add_custom_type(
		"ProtonGraph",
		"Node3D",
		preload("./src/proton_graph.gd"),
		preload("./icons/proton_graph.svg")
	)


func _exit_tree():
	remove_custom_type("ProtonGraph")
	remove_inspector_plugin(_remote_status_inspector_plugin)
