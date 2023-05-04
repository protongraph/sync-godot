@tool
extends EditorProperty


const REMOTE_STATUS_PANEL := preload("./remote_status_panel.tscn")

var _panel


func _init():
	_panel = REMOTE_STATUS_PANEL.instantiate()
	add_child(_panel)
	set_bottom_editor(_panel)


func set_node(object) -> void:
	_panel.set_node(object)
