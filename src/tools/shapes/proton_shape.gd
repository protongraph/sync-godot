tool
extends Spatial


signal changed
signal property_changed


func _ready() -> void:
	set_notify_local_transform(true)


func _notification(type: int):
	if type == NOTIFICATION_TRANSFORM_CHANGED:
		_on_changed()


func _on_changed():
	emit_signal("changed", self)
	emit_signal("property_changed")
