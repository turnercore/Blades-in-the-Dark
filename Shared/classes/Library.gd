class_name Library
extends Reference

const ID_LENGTH: = 5
var resources: = {}

func setup(books, reset: = false)-> void:
	if reset:
		resources.clear()
	if books is Dictionary:
		for key in books:
			add(books[key])
	elif books is Array:
		for book in books:
			add(book)


func add(book:Dictionary)-> NetworkedResource:
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
		return result


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


func clear()-> Array:
	var cleared_data:Array
	for id in resources:
		cleared_data.append(resources[id].delete())
	resources.clear()

	return cleared_data


func delete_id(id:String)-> Dictionary:
	if not resources.has(id):
		print("can't find resource by id to delete")
		return {}

	var resource:NetworkedResource = get(id)
	var data:Dictionary = resource.data
	resource.delete()
	resources.erase(id)
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
