class_name NetworkedResource
extends Resource

enum RESOURCE_OP_CODES {
	UPDATE,
	ADD,
	DELETE
}

var id:String setget ,_get_id
var data:Dictionary


signal property_changed(property, value)
signal property_removed(property)
signal deleted

func setup(setup_data:Dictionary)-> void:
	data = setup_data
	self.id = setup_data.id if "id" in setup_data else ""
	if not NetworkTraffic.is_connected("networked_resource_updated", self, "_on_networked_resource_updated"):
		NetworkTraffic.connect("networked_resource_updated", self, "_on_networked_resource_updated")


func get_property(property:String):
	var result
	if data.has(property):
		result = data[property]
	else:
		result = "PROPERTY NOT FOUND"

	if result is String:
		result = str2var(result)
	return result


func get_vec2(property:String)->Vector2:
	var result:Vector2
	if not data.has(property):
		return Vector2.ZERO
	elif data[property] is Vector2:
		result = data[property]
	elif data[property] is String:
		result = str2var("Vector2"+data[property])
	return result


func get_color(property:String)->Color:
	return str2var(data[property]) if data.has(property) else Color.black


func has_property(property:String)-> bool:
	if data.has(property):
		if data[property] is bool:
			return true
		elif data[property]:
			return true
	return false


func import(import_data:Dictionary, update_network: = true)-> void:
	var updated_data: = {}
	for property in import_data:
		var value = import_data[property]
		if data.has(property):
			if data[property] != value:
				data[property] = value
				updated_data[property] = value
				emit_signal("property_changed", property, value)

	if update_network and not updated_data.empty():
		send_update_over_network(updated_data)


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

	#Reverses any var2str data that may be in there and returns the correct value, deeply
	if result is String:
		result = str2var(result)
	elif result is Dictionary or result is Array:
		propagate_str2var(result)

	return result


func propagate_str2var(data):
	if data is Dictionary:
		for key in data.keys():
			if data[key] is String:
				data[key] = str2var(data[key])
			elif data[key] is Dictionary or data[key] is Array:
				propagate_str2var(data[key])
	elif data is Array:
		var index:int = 0
		for property in data:
			if property is String:
				var formatted_property = str2var(property)
				if not formatted_property is String:
					data.insert(index, formatted_property)
					data.erase(property)
			elif property is Dictionary or property is Array:
				propagate_str2var(property)
			index += 1



func update(path:String, value, update_network: = true):
	var split:PoolStringArray = path.split(".")
	if split.empty():
		return
	var result = data
	var i: = 0

	for property in split:
		#is this the last property in the array? If so do the setter function
		if i == split.size()-1:
			if property.is_valid_integer():
				var index:int = int(property)
				if index < result.size() and index >= 0:
					if typeof(result[index]) == typeof(value) and result[index] != value:
						result[index] = value
						if update_network: send_update_over_network({path : value, "op_code":RESOURCE_OP_CODES.UPDATE})
						emit_signal("property_changed", path, value)

				else:
					print("Invalid path for find() Index out of range | Path: " + path)
					return
			else:
				if result.has(property):
					if typeof(result[property]) == typeof(value) and result[property] != value:
						result[property] = value
						if update_network: send_update_over_network({path : value, "op_code":RESOURCE_OP_CODES.UPDATE})
						emit_signal("property_changed", path, value)
				else:
					print("Invalid path for find() property not in data| Path: " + path)
					return
		#Else Keep searching for the property
		else:
			if property.is_valid_integer():
				var index:int = int(property)
				if index >= result.size():
					print("Invalid path for find() Index out of range | Path: " + path)
				else: result = result[index]
			else:
				if result.has(property):
					result = result[property]
				else:
					print("Invalid path for find() property not in data| Path: " + path)
			i += 1


func add(path:String, value = "", update_network: = true)-> void:
	#Will Create path as it goes
	var split:PoolStringArray = path.split(".")
	if split.empty():
		return

	var current_property:String = split[0]
	var result = data
	var i: = -1

	for property in split:
		i += 1
		if i == split.size()-1:
			 #At the end of the path
			result[property] = value
			if update_network: send_update_over_network({path : value, "op_code" : RESOURCE_OP_CODES.ADD})
		else:
			if property.is_valid_integer():
				var index:int = int(property)
				if index > result.size():
					print("index out of range for this add() call " + path)
				elif index == result.size():
					result.append({})
					result = result.back()
				else:
					result = result[index]
			else:
				if not property in result:
					result[property] = {}
				result = result[property]


func remove(path:String, update_network: = true)-> void:
	var split:PoolStringArray = path.split(".")
	if split.empty():
		return
	var result = data
	var i: = 0

	for property in split:
		#is this the last property in the array? If so do the setter function
		if i == split.size()-1:
			if property.is_valid_integer():
				var index:int = int(property)
				if index < result.size() and index >= 0:
					result.remove(index)
					if update_network: send_update_over_network({"property": path, "op_code":RESOURCE_OP_CODES.REMOVE})
					emit_signal("property_removed", path)

				else:
					print("Invalid path for remove() Index out of range | Path: " + path)
					return
			else:
				if result.has(property):
					result.erase(property)
					if update_network: send_update_over_network({"property" : path, "op_code":RESOURCE_OP_CODES.REMOVE})
					emit_signal("property_removed", path)
				else:
					print("Invalid path for remove() property not in data| Path: " + path)
					return
		#Else Keep searching for the property
		else:
			if property.is_valid_integer():
				var index:int = int(property)
				if index >= result.size():
					print("Invalid path for remove() Index out of range | Path: " + path)
				else: result = result[index]
			else:
				if result.has(property):
					result = result[property]
				else:
					print("Invalid path for remove() property not in data| Path: " + path)
			i += 1


func send_update_over_network(updated_data:Dictionary)-> void:
	if not ServerConnection.is_connected_to_server:
		return
	if not "op_code" in data: return
	updated_data["id"] = self.id
	var str_data:String = var2str(updated_data)
	var result:int = yield(NetworkTraffic.send_data_async(NetworkTraffic.OP_CODES.NETWORKED_RESOURCE_UPDATED, str_data), "completed")
	if result != OK:
		print("error sending networked data over the network")

#Forces the resource to send all data over the network
#Useful when you do something that doesn't trigger an update, like appending to an array
func trigger_update(property:String)-> void:
	var updated_value = find(property)
	var data: = {
		property : updated_value
	}
	emit_signal("property_changed", property, updated_value)
	send_update_over_network(data)


func delete(update_network: = true)-> Dictionary:
	emit_signal("deleted")
	if update_network: send_update_over_network({"op_code" : RESOURCE_OP_CODES.DELETE})
	return data


func _on_networked_resource_updated(network_data:Dictionary)-> void:
	if "id" in network_data and network_data.id == self.id:
		print("got networked resource update from network")
		if not "op_code" in network_data: return

		match network_data.resource_op_code:
			RESOURCE_OP_CODES.ADD:
				for property in network_data:
					if property == "id": continue
					if property == "op_code":continue
					add(property, network_data[property], false)
			RESOURCE_OP_CODES.UPDATE:
				for property in network_data:
					if property == "id": continue
					if property == "op_code":continue
					update(property, network_data[property], false)
			RESOURCE_OP_CODES.DELETE:
				delete(false)
			_:
				print("invalid network resource op code")


func _get_id()->String:
	if not id or id == "":
		id = Globals.generate_id(5)
	return id
