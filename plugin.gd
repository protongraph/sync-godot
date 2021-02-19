tool
extends EditorPlugin


# ProtonGraph is a node based tool for procedural content generation.
# This addons takes away the burden of exporting and importing the results
# from the standalone software and directly syncs the results to the editor.
#
# This means you need to run the standalone application alongside the Godot
# engine when using this plugin. If you don't, nothing will happen and you
# should see an error warning in the inspector panel.


var _status_inspector_plugin: EditorInspectorPlugin
var _editor_gizmo_plugins: Array


func _enter_tree() -> void:
	_status_inspector_plugin = preload("src/tools/remote_status_plugin/status_plugin.gd").new()
	add_inspector_plugin(_status_inspector_plugin)

	add_custom_type(
		"ProtonGraph",
		"Spatial",
		preload("src/proton_graph.gd"),
		preload("icons/proton_graph.svg")
	)
	add_custom_type(
		"ProtonShapeBox",
		"Spatial",
		preload("src/tools/shapes/proton_shape_box.gd"),
		preload("icons/proton_graph.svg")
	)

	_register_editor_gizmos()


func _exit_tree():
	remove_inspector_plugin(_status_inspector_plugin)
	remove_custom_type("ProtonGraph")
	remove_custom_type("ProtonShapeBox")
	_deregister_editor_gizmos()


func _register_editor_gizmos() -> void:
	if not _editor_gizmo_plugins:
		_editor_gizmo_plugins = []

	if _editor_gizmo_plugins.size() > 0:
		_deregister_editor_gizmos()

	var box_gizmo = preload("src/tools/shapes/proton_shape_box_gizmo_plugin.gd").new()
	box_gizmo.editor_plugin = self
	_editor_gizmo_plugins.append(box_gizmo)
	add_spatial_gizmo_plugin(box_gizmo)


func _deregister_editor_gizmos() -> void:
	if _editor_gizmo_plugins:
		for gizmo in _editor_gizmo_plugins:
			remove_spatial_gizmo_plugin(gizmo)
	_editor_gizmo_plugins = []
