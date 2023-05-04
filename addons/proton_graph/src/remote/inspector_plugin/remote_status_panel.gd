@tool
extends Control


const PROTON_GRAPH := preload("../../proton_graph.gd")
const REMOTE := preload("../remote.gd")


var _node: PROTON_GRAPH
var _remote: REMOTE

@onready var _icon_connected: TextureRect = %IconConnected
@onready var _icon_disconnected: TextureRect = %IconDisconnected
@onready var _status_label: Label = %StatusLabel
@onready var _reconnect_button: Button = %ReconnectButton
@onready var _rebuild_button: Button = %RebuildButton
@onready var _reload_graph_button: Button = %ReloadGraphButton


func _ready():
	_refresh_gui()

	_reconnect_button.pressed.connect(_on_reconnect_pressed)
	_reload_graph_button.pressed.connect(_on_reload_graph_pressed)
	_rebuild_button.pressed.connect(_on_rebuild_pressed)


func set_node(node: PROTON_GRAPH) -> void:
	# Cleanup previous signal connections if any.
	if is_instance_valid(_remote):
		if _remote.connection_established.is_connected(_show_as_connected):
			_remote.connection_established.disconnect(_show_as_connected)
		if _remote.connection_lost.is_connected(_show_as_disconnected):
			_remote.connection_lost.disconnect(_show_as_disconnected)

	# Set the currently selected ProtonGraph node.
	_node = node
	_remote = node._remote

	# Listen to connection status changes.
	_remote.connection_established.connect(_show_as_connected)
	_remote.connection_lost.connect(_show_as_disconnected)


func _refresh_gui() -> void:
	if not _remote:
		return

	if _remote.is_connected_to_server():
		_show_as_connected()
	else:
		_show_as_disconnected()


func _show_as_connected() -> void:
	_icon_connected.visible = true
	_icon_disconnected.visible = false
	_reconnect_button.visible = false
	_status_label.text = "Connected"
	_rebuild_button.disabled = false


func _show_as_disconnected() -> void:
	_icon_connected.visible = false
	_icon_disconnected.visible = true
	_reconnect_button.visible = true
	_status_label.text = "Disconnected"
	_rebuild_button.disabled = true


func _on_reconnect_pressed():
	if _remote:
		_remote.connect_to_server()


func _on_rebuild_pressed():
	_node.rebuild()


func _on_reload_graph_pressed():
	_node.reload_node_graph()
