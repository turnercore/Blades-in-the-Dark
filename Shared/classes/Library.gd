class_name Library
extends Reference

const ID_LENGTH: = 5
var resources: = {}
var online: = false setget ,_get_online
var library_name:String

signal resource_added(resource)
signal resource_removed(resource)
signal unloaded

func setup(books, reset: = false)-> void:
	if reset:
		resources.clear()
	if books is Dictionary:
		for key in books:
			add(books[key])
	elif books is Array:
		for book in books:
			add(book)

	if not NetworkTraffic.is_connected("networked_resource_created", self, "_on_networked_resource_created"):
		NetworkTraffic.connect("networked_resource_created", self, "_on_networked_resource_created")
	if not NetworkTraffic.is_connected("networked_resource_removed", self, "_on_networked_resource_removed"):
		NetworkTraffic.connect("networked_resource_removed", self, "_on_networked_resource_removed")


func _on_networked_resource_created(data:Dictionary)-> void:
	if not "library" in data or data.library != library_name:
		return
	else:
		add(data, false)


func _on_networked_resource_removed(data:Dictionary)-> void:
	if not "library" in data or data.library != library_name or not "id" in data:
		return
	else:
		delete_id(data.id, false)


func add(book:Dictionary, send_data: = true)-> NetworkedResource:
	var result:NetworkedResource
	var id:String

	if "id" in book:
		id = str(book.id)
		if resources.has(id):
			return resources[id]
		else:
			result = NetworkedResource.new()
			result.setup(book)
			resources[id] = result
			result.id = id
			emit_signal("resource_added", result)
			if online and send_data:
				add_to_network(result.data)
			return result
	else:
		#Check to see if the data in the book is the same as something the library already has
		for key in resources:
			if areDictsEqual(resources[key].data, book):
				return resources[key]
		id = generate_id(ID_LENGTH)
		result = NetworkedResource.new()
		result.setup(book)
		resources[id] = result
		result.id = id
		emit_signal("resource_added", result)
		if online and send_data:
			add_to_network(result.data)
		return result


func add_to_network(data:Dictionary)-> void:
	if online and library_name:
		data["library"] = library_name
		var result:int = yield(NetworkTraffic.send_data_async(NetworkTraffic.OP_CODES.NETWORKED_RESOURCE_CREATED, data), "completed")
		if result != OK:
			print("ERROR sending update over network")
			print(ServerConnection.error_message)


func remove_from_network(id:String)-> void:
	if online and library_name:
		var data: = {
			"id": id,
			"library": library_name
		}
		var result:int = yield(NetworkTraffic.send_data_async(NetworkTraffic.OP_CODES.NETWORKED_RESOURCE_REMOVED, data), "completed")
		if result != OK:
			print("ERROR sending update over network")
			print(ServerConnection.error_message)


func areDictsEqual(a: Dictionary, b: Dictionary) -> bool:
	if not a or not b:
		return false
	if a.size() != b.size():
		return false
	for key in a.keys():
		if not b.has(key):
			return false
		if a[key] != b[key]:
			return false
	return true

#Find all the resources that have a property that is a certain value
func search(search_property:String, value)-> Array:
	var result: = []
	if search_property == "id" and value is String:
		result.append(get(value))
	else:
		for id in resources:
			for property in resources[id].data:
				if property == search_property:
					if typeof(resources[id].data[property]) == typeof(value) and resources[id].data[property] == value:
						result.append(resources[id])
	return result


func get(id:String)-> NetworkedResource:
	var result:NetworkedResource
	if resources.has(id):
		result = resources[id]
	return result

func unload()-> void:
	resources = {}
	emit_signal("unloaded")


func burn_down()-> Array:
	var cleared_data:Array
	for id in resources:
		cleared_data.append(resources[id].delete())
	resources.clear()

	return cleared_data


func delete_id(id:String, update_network: = true)-> Dictionary:
	if not resources.has(id):
		print("can't find resource by id to delete")
		return {}

	var resource:NetworkedResource = get(id)
	var data:Dictionary = resource.data
	emit_signal("resource_removed", resource)
	resource.delete()
	resources.erase(id)

	if online and update_network:
		remove_from_network(id)
	return data


func find_id(search_property:String, value)-> String:
	var result: =""
	for id in resources:
		for property in resources[id].data:
			if property == search_property:
				if typeof(resources[id].data[property]) == typeof(value) and resources[id].data[property] == value:
					result = id
					break
	return result


func generate_id(characters:int)-> String:
	var possible_characters: = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"
	var id:=""
	for character in characters:
		var rand:int = randi() % possible_characters.length()
		id += possible_characters[rand]

	#In the unlikely event that this generates an ID that's already taken, generate another
	if resources.has(id):
		id = generate_id(characters)

	return id


func get_catalogue()->Array:
	var catalogue:Array = []
	for id in resources:
		catalogue.append(resources[id])
	return catalogue


func _get_online()-> bool:
	if ServerConnection.is_connected_to_server and GameData.online:
		online = true
	else:
		online = false
	return online
