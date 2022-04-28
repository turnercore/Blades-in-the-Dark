class_name NetworkedResource
extends Resource

var id:String
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
		result = result
	return  result


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
				emit_changed()
	if update_network and not updated_data.empty():
		updated_data["id"] = id
		var result:int = yield(NetworkTraffic.send_data_async(NetworkTraffic.OP_CODES.NETWORKED_RESOURCE_UPDATED, updated_data), "completed")
		if result != OK:
				print("error sending networked data over the network")


func update(property:String, value, update_network: = true)-> void:
	var updated_data: = {}
	if value is Vector2 or value is Color:
		value = str(value)
	if data.has(property):
		if data[property] != value:
			data[property] = value
			updated_data[property] = value
		emit_signal("property_changed", property, value)
		emit_changed()
		if update_network and not updated_data.empty() and ServerConnection.is_connected_to_server:
			updated_data["id"] = id
			var result:int = yield(NetworkTraffic.send_data_async(NetworkTraffic.OP_CODES.NETWORKED_RESOURCE_UPDATED, updated_data), "completed")
			if result != OK:
				print("error sending networked data over the network")


func delete()-> Dictionary:
	emit_signal("deleted")
	return data


func _on_networked_resource_updated(network_data:Dictionary)-> void:
	for property in network_data:
		if data.has(property):
			data[property] = network_data[property]
		else:
			print("Property: %s not found in resource ID %s" % [property, id])
