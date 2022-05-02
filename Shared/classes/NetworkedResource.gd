class_name NetworkedResource
extends Resource

var id:String setget ,_get_id
var data:Dictionary


signal property_changed(property, value)
signal deleted

func setup(setup_data:Dictionary)-> void:
	data = setup_data
	self.id = setup_data.id if "id" in setup_data else ""
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
		result = Globals.str_to_vec2(data[property])
	return result


func get_color(property:String)->Color:
	return Globals.str_to_color(data[property]) if data.has(property) else Color.black


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
		updated_data["id"] = id
		var result:int = yield(NetworkTraffic.send_data_async(NetworkTraffic.OP_CODES.NETWORKED_RESOURCE_UPDATED, updated_data), "completed")
		if result != OK:
				print("error sending networked data over the network")


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
	if result is String:
		result = str2var(result)
	return result


func update(path:String, value, update_network: = true):
	if value is String:
		value = str2var(value)
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
					if result[index] != value:
						result[index] = value
						if update_network: send_update_over_network({path : value})

				else:
					print("Invalid path for find() Index out of range | Path: " + path)
					return
			else:
				if result.has(property):
					if result[property] != value:
						result[property] = value
						if update_network: send_update_over_network({path : value})
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
				if result.has(property):
					result = result[property]
				else:
					print("Invalid path for find() property not in data| Path: " + path)
			i += 1


func send_update_over_network(updated_data:Dictionary)-> void:
	if not ServerConnection.is_connected_to_server:
		return

	print("Sending networked resource update over network")
	updated_data["id"] = self.id
	var result:int = yield(NetworkTraffic.send_data_async(NetworkTraffic.OP_CODES.NETWORKED_RESOURCE_UPDATED, updated_data), "completed")
	if result != OK:
		print("error sending networked data over the network")


func delete()-> Dictionary:
	emit_signal("deleted")
	return data


func _on_networked_resource_updated(network_data:Dictionary)-> void:
	if "id" in network_data and network_data.id == self.id:
		print("got networked resource update from network")
		for property in network_data:
			if property == "id": continue
			if data.has(property):
				data[property] = network_data[property]
				emit_signal("property_changed", property, network_data[property])
				emit_changed()
			else:
				print("Property: %s not found in resource ID %s" % [property, id])


func _get_id()->String:
	if not id:
		id = Globals.generate_id(5)
	return id
