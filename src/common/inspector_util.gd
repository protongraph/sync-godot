extends Node


static func is_property(node_id: String) -> bool:
	return "inspector" in node_id


static func to_variant_type(value):
	if value is int:
		return TYPE_INT
	if value is float:
		return TYPE_REAL
	elif value is bool:
		return TYPE_BOOL
	elif value is String:
		return TYPE_STRING
	elif value is Vector2:
		return TYPE_VECTOR2
	elif value is Vector3:
		return TYPE_VECTOR3
	elif value is Curve:
		return TYPE_OBJECT

	return TYPE_NIL


static func serialize(node) -> Array:
	print("In serialize")
	var res = []
	for vname in node._exposed_variables.keys():
		var d = {}
		d["name"] = vname.trim_prefix("Template/")
		if node._exposed_variables[vname].has("value"):
			d["value"] = node._exposed_variables[vname]["value"]
		else:
			d["value"] = node._exposed_variables[vname]["default_value"]
		res.append(d)
	print("Res ", res)
	return res
