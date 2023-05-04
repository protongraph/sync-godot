extends Node


# Utility script to load and parse tpgn files.


var _file_path: String
var _pinned_variables := {} # Key: variable name, Value: type


func clear() -> void:
	_file_path = ""
	_pinned_variables.clear()


func parse(file_path: String) -> void:
	clear()

	# Load the node graph file
	var file := ConfigFile.new()
	var err = file.load(file_path)
	if err != OK:
		return

	_file_path = file_path

	for node_name in file.get_sections():
		var data: Dictionary = file.get_value(node_name, "external_data", {})

		# Search for pinned variables
		if "pinned" in data:
			var local_values: Dictionary = file.get_value(node_name, "local_values", {})
			var pinned: Dictionary = data["pinned"]

			for input_idx in pinned.keys():
				var variable_name: String = pinned[input_idx]
				var value = local_values[input_idx]
				_pinned_variables[variable_name] = value


func get_pinned_variables() -> Dictionary:
	return _pinned_variables
