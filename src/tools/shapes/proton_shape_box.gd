tool
extends "./proton_shape.gd"


export var size := Vector3.ONE setget set_size

var center_offset := Vector3.ZERO setget set_center_offset


func set_size(val: Vector3) -> void:
	size = val
	_on_changed()


func set_center_offset(val: Vector3) -> void:
	center_offset = val
	_on_changed()


func get_aabb() -> AABB:
	var position: Vector3 = get_global_transform().origin + center_offset
	return AABB(position, size)


