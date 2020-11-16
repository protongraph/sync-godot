tool
extends Object


# Dictionaries received from the websocket sometimes have small inconsistencies
# like having everything as strings, even numerical values, or having integers
# stored as floats. This method (along with format_value) attempt to fix that.
static func fix_types(dict: Dictionary) -> Dictionary:
	var res := {}
	for key in dict.keys():
		var new_key = format_value(key)
		res[new_key] = format_value(dict[key])
	
	return res


# Takes an arbitrary value and try to recover the base type. Returns the
# original value if nothing can be infered.
static func format_value(value):
	if value is Dictionary:
		return fix_types(value)
		
	if value is String:
		if value.is_valid_integer():
			return value.to_int()
		
		if value.is_valid_float():
			return value.to_float()
		
		var vector = string_to_vector(value)
		if vector:
			return vector

	if value is float:
		if is_equal_approx(round(value), value):
			return int(value)
	
	if value is Array:
		for i in value.size():
			value[i] = format_value(value[i])
		return value

	return value


static func string_to_vector(string: String):
	if not string.begins_with('(') or not string.ends_with(')'):
		return null
	
	string = string.trim_prefix('(')
	string = string.trim_suffix('(')
	var tokens = string.split(',', false)
	if tokens.size() == 2:
		var vec2 = Vector2.ZERO
		if tokens[0].is_valid_float() and tokens[1].is_valid_float():
			vec2.x = tokens[0].to_float()
			vec2.y = tokens[1].to_float()
			return vec2
	
	elif tokens.size() == 3:
		var vec3 = Vector3.ZERO
		for token in tokens:
			if not token.is_valid_float():
				return null
		
		vec3.x = tokens[0].to_float()
		vec3.y = tokens[1].to_float()
		vec3.z = tokens[2].to_float()
		return vec3
	
	return null
