extends Node

export var data: = {
	"color": "(0,1,1,1)",
	"prop1": {
		"subprop1": {
			"array" : [
				"a",
				"b",
				"c"
			]
		},
		"subprop2": {
			"array" : [
				"a",
				"b",
				"c"
			]
		}
	},
	"prop2": {
		"subprop1": {
			"array" : [
				"a",
				"b",
				"c"
			]
		},
		"subprop2": {
			"array" : [
				"a",
				"b",
				"c"
			]
		}
	}
}

func find(path:String):
	#prop1.prop2.array.0
	var split:PoolStringArray = path.split(".")
	if split.empty():
		return

	var current_property:String = split[0]
	var result = data

	for property in split:
		if property.is_valid_integer():
			var index:int = int(property)
			if index >= result.size():
				return "Invalid path for find() Index out of range | Path: " + path
			result = result[index]
		else:
			if property in result:
				result = result[property]
			else:
				return "Invalid path for find() property not in data| Path: " + path
	return result


func set_prop_with_path(path:String, value):
	var split:PoolStringArray = path.split(".")
	if split.empty():
		return
	var current_property:String = split[0]
	var result = data
	var i: = 0

	for property in split:
		#is this the last property in the array? If so do the setter function
		if i == split.size()-1:
			if property.is_valid_integer():
				var index:int = int(property)
				if index >= result.size():
					print("Invalid path for find() Index out of range | Path: " + path)
					return
				else:
					result[index] = value
			else:
				if property in result:
					result[property] = value
				else:
					print("Invalid path for find() property not in data| Path: " + path)
					return
		#ELse Keep searching for the property
		else:
			if property.is_valid_integer():
				var index:int = int(property)
				if index >= result.size():
					print("Invalid path for find() Index out of range | Path: " + path)
				else: result = result[index]
			else:
				if property in result:
					result = result[property]
				else:
					print("Invalid path for find() property not in data| Path: " + path)
			i += 1


func _on_Button_pressed() -> void:
	$Label.text = str(find($LineEdit.text))


func _on_Button2_pressed() -> void:
	set_prop_with_path($LineEdit.text, $LineEdit2.text)
