tool
extends Node


var _node # The selected ProtonGraph node

onready var _icon_check: TextureRect = $VBoxContainer/HBoxContainer/CenterContainer/IconsContainer/Check
onready var _icon_cross: TextureRect = $VBoxContainer/HBoxContainer/CenterContainer/IconsContainer/Cross
onready var _connexion_label: Label = $VBoxContainer/HBoxContainer/ConnexionLabel
onready var _reconnect_button: Button = $VBoxContainer/HBoxContainer/ReconnectButton
onready var _rebuild_button: Button = $VBoxContainer/RebuildButton


func _ready():
	_refresh_gui()


func set_node(node) -> void:
	_node = node
	_node._protocol._client.connect("connection_etablished", self, "_show_as_connected")
	_node._protocol._client.connect("connection_closed", self, "_show_as_disconnected")


func _refresh_gui() -> void:
	if not _node or not _node._initialized:
		return

	if _node._protocol._client.is_connected_to_server():
		_show_as_connected()
	else:
		_show_as_disconnected()


func _show_as_connected() -> void:
	_icon_check.visible = true
	_icon_cross.visible = false
	_reconnect_button.visible = false
	_connexion_label.text = "Connected"


func _show_as_disconnected() -> void:
	_icon_check.visible = false
	_icon_cross.visible = true
	_reconnect_button.visible = true
	_connexion_label.text = "Disconnected"


func _on_reconnect_pressed():
	if _node:
		_node._protocol._start_client()


func _on_rebuild_pressed():
	_node.rebuild()


func _on_reload_template_pressed():
	_node.reload_template()
