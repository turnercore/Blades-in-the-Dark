class_name Playbook
extends Resource

#Path to the srd_json
var srd_json: String = ""
export var name:String
export var abilities:Dictionary
export var coin:Dictionary = {
	"max": 4,
	"available" : 0,
	"stash" : 0
}
export var contacts:Dictionary
export var type:String setget _change_type
export var notes:String
export (Dictionary) var experience
export var projects:Dictionary

#Catch all for random data that isn't properly configured (this didn't work...)
export var data:Dictionary

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
var insight: int = 0
var prowess: int = 0
var resolve: int = 0




var needs_setup: = true

func setup(json: String, type: String, overwrite:bool = false)-> void:
	needs_setup = false



func get_insight()->int:
	var total: = 0

	for stat in stats.insight:
		if int(stat) >= 1:
			total += 1

	return total

func get_prowess()->int:
	var total: = 0

	for stat in stats.prowess:
		if stat >= 1:
			total += 1

	return total

func get_resolve()->int:
	var total: = 0

	for stat in stats.resolve:
		if stat >= 1:
			total += 1

	return total



func get_defaults(json: String):
	var file = File.new()
	if not file.file_exists(json):
		print("unable to find file: " + json)
	file.open(json, File.READ)
	var data = parse_json(file.get_as_text())
	return data


func save_path(path_map: String, value)-> bool:
	var path: = path_map.split(".", false) as Array
	var jumps: int = 0
	var cursor = self

	#Check to see if the property exists in the Resource
	if not (path[0] in self):
		print(path_map + " is not in the property list for crew playbook")
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
	return true


func find(path_map: String):
	var path: = path_map.split(".", false)
	var jumps: int = 0
	var updated_property
	while jumps < path.size():
		if jumps == 0:
			if path[jumps] in self:
				updated_property = self.get(path[jumps])
				jumps += 1
			else:
				return false
		else:
			if path[jumps] in updated_property:
				updated_property = updated_property[path[jumps]]
				jumps += 1
			else:
				return false

	return updated_property

func _change_type(new_type:String)-> void:
	pass
