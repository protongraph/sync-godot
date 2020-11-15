tool
extends Node


# This script is attached to each ProtonGraph Inputs node. It monitors the
# changes of each children and notify the parent so it can rerun the generation
# immediately.


signal input_changed


func _ready() -> void:
	for c in get_children():
		if not c.has_user_signal("input_changed"):
			continue
		
		if c.is_connected("input_changed", self, "_on_input_changed"):
			continue
		
		c.connect("input_changed", self, "_on_input_changed")


func add_child(node, legible_unique_name = false) -> void:
	.add_child(node, legible_unique_name)
	if node.has_user_signal("input_changed"):
		node.connect("input_changed", self, "_on_input_changed")


func _on_input_changed(node) -> void:
	emit_signal("input_changed", node)

