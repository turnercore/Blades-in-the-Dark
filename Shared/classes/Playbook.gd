class_name Playbook
extends Resource

#Path to the srd_json
export var id:String
var srd_json: String = 'res://srd/default_srd.json'
export var version:= ""
export var name:String
export var abilities:Dictionary
export var coin:Dictionary = {
	"max": 4,
	"available" : 0,
	"stash" : 0
}
export var contacts:Dictionary
export var type:String
export var notes:String
export (Dictionary) var experience: = {
	"playbook": 0,
	"insight": 0,
	"prowess": 0,
	"resolve": 0,
}
export var projects:Dictionary
export (Dictionary) var stats: Dictionary = {
	"insight": {
		"hunt": 0,
		"study": 0,
		"survey": 0,
		"tinker": 0
	},
	"prowess": {
		"finesse": 0,
		"prowl": 0,
		"skirmish": 0,
		"wreck": 0
	},
	"resolve": {
		"attune": 0,
		"command": 0,
		"consort": 0,
		"sway": 0
	}
}
export var insight: int = 0
export var prowess: int = 0
export var resolve: int = 0

export (bool) var needs_setup: = true

signal property_changed(property_field)


func _init() -> void:
	if not self.is_connected("property_changed", self, "_on_property_changed"):
		connect("property_changed", self, '_on_property_changed')


func setup(json_or_file_path_to_json, starting_type: String, _overwrite:bool = false)-> void:
	needs_setup = false
	if not self.is_connected("property_changed", self, "_on_property_changed"):
		connect("property_changed", self, '_on_property_changed')


func _on_property_changed(_data)-> void:
	emit_changed()


func set_property(property: String, value)-> void:
	if property in self:
		set(property, value)
		emit_signal("property_changed", property)
	else:
		print("Error, " + property + " not found in Playbook properties")


func set_ability(key, value)-> void:
	abilities[key] = value
	emit_signal("property_changed", "abilities."+key)


func set_contacts(key, value)-> void:
	contacts[key] = value
	emit_signal("property_changed", "contacts."+key)


func set_coin(key, value)-> void:
	coin[key] = value
	emit_signal("property_changed", "coin."+key)


func set_projects(key, value)-> void:
	projects[key] = value
	emit_signal("property_changed", "projects."+key)


func get_insight()->int:
	var total: = 0

	for stat in stats.insight:
		if stats.insight[stat] >= 1:
			total += 1

	return total


func get_prowess()->int:
	var total: = 0

	for stat in stats.prowess:
		if stats.prowess[stat] >= 1:
			total += 1

	return total


func get_resolve()->int:
	var total: = 0

	for stat in stats.resolve:
		if stats.resolve[stat] >= 1:
			total += 1

	return total


func get_defaults(json_file_path: String):
	var file = File.new()
	if not file.file_exists(json_file_path):
		print("ERROR IN GET DEFAULTS PLAYBOOK")
		print("unable to find json file: " + json_file_path)
	file.open(json_file_path, File.READ)
	var data = parse_json(file.get_as_text())
	return data


func package_as_json()-> String:
	#This function is certainly going to need some work so that it matches the SRD rules exactly,
	#basically this needs to package the playbook as an SRD so it can be loaded into
	var json:String
	var dict: = {}

	var ignored_props:=[
		"Reference",
		"Resource",
		"resource_local_to_scene",
		"resource_path",
		"resource_name",
		"script",
		"Script Variables"
	]

	for property in self.get_property_list():
		if ignored_props.has(property.name):
			continue
		dict[property.name] = get(property.name)

	json = JSON.print(dict)
	return json


func load_from_json(json:String)-> void:
	var result = JSON.parse(json).result
	for property in result:
		if property in self:
			set(property, result[property])


func save(path_map: String, value)-> bool:
	var path: = path_map.split(".", false) as Array
	var jumps: int = 0
	var cursor = self

	#Check to see if the property exists in the Resource
	if not (path[0] in self):
		return false

	while jumps < path.size() - 1:
		if jumps == 0:
			if not (path[jumps] in self):
				self[path[jumps]] = {}
			cursor = self.get(path[jumps])
			jumps += 1
		else:
			if not (path[jumps] in cursor):
				cursor[path[jumps]] = {}
			cursor = cursor[path[jumps]]
			jumps += 1

	if not path.back() in cursor: cursor[path.back()] = null
	cursor[path.back()] = value
	emit_signal("property_changed", path_map)
	return true


func find(path_map: String):
	var path: = path_map.split(".", false)
	var jumps: int = 0
	var updated_property

	while jumps < path.size():
		var index: = 0
		var is_array: = false
		var check_array: = path[jumps].split("-", false, 2)
		if check_array.size() > 1:
			#This is an array
			index = int(check_array[1])
			path[jumps] = check_array[0]
			is_array = true
		if jumps == 0:
			if path[jumps] in self:
				updated_property = self.get(path[jumps])
				if is_array and updated_property is Array and index < updated_property.size():
					updated_property = updated_property[index]
				jumps += 1
			else:
				return
		else:
			if path[jumps] in updated_property:
				updated_property = updated_property[path[jumps]]
				if is_array and updated_property is Array and index < updated_property.size():
					updated_property = updated_property[index]
				jumps += 1
			else:
				return
	return updated_property


#Put in the playbook property you want, the srd, and the field and get all the defaults added. Bosh
func setup_property(property:String, srd:Dictionary, srd_field:String = "", overwrite: bool = false) -> void:
	var current_property = get(property)
	if srd_field == "": srd_field = property
	var claimed_properties: = {}
	if not overwrite:
		for key in current_property:
			if "claimed" in current_property[key] and current_property[key].claimed:
				claimed_properties[key] = current_property[key].duplicate(true)
			elif "notes" in current_property[key] and current_property[key].notes:
				claimed_properties[key] = current_property[key].duplicate(true)
			elif "relationship" in current_property[key] and current_property[key].relationship:
				claimed_properties[key] = current_property[key].duplicate(true)

	set(property, claimed_properties)

	var field = srd[srd_field] if srd_field in srd else false
	if not field:
		print("ERROR couldn't set property: %s while looking for srd_field: %s" % [property, srd_field])
		return

	for key in field:
		if not ("class" in srd[srd_field][key]) or srd[srd_field][key].class == self.type or srd[srd_field][key].class == "all":
			var new_property:Dictionary = srd[srd_field][key]
			var esc_key:String = escape_key(key)
			var self_property = get(property)
			self_property[esc_key] = new_property


func escape_key(key:String)->String:
	return key.c_escape().strip_edges().to_lower().replace(" ", "_")


func unescape_key(key:String)->String:
	return key.c_unescape().replace("_", " ").capitalize()

func _no_set(_v)-> void:
	return
