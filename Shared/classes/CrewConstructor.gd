class_name CrewConstructor
extends Reference

#Path to the srd_json
export var id:String
var srd_json: String = 'res://srd/bitd_srd.json'
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

const DEFAULT_CREW_PLAYBOOK_DATA: = {
	"id": "",
	"type": ""
}
var PLAYBOOK_TYPE: = "crew"

export (int) var heat: int = 0
export (int) var wanted_level: int = 0
export (String) var reputation
export (int) var reputation_level: = 0
export (int) var hold_level: int = 0
export (int) var tier: int = 0
export (Dictionary) var upgrades:Dictionary
export (Dictionary) var lair: = {
	"name" : "",
	"location" : "",
	"description": ""
}
export (Dictionary) var hunting_grounds: = {
	"location": "",
	"description": ""
}
export (Dictionary) var cohorts:Dictionary
export (Dictionary) var claims:Dictionary
export (Dictionary) var prison_claims:Dictionary
export (Dictionary) var map:Dictionary
var operation_type

#Builds the dictonary from the default data and the SRD data
func build(type:String, srd:Dictionary)-> Dictionary:
	var data:= {}
	return data


func setup_claims(defaults:Dictionary, crew_type: String)->void:
	#clear defaults if any exist
	for key in self.claims:
		if claims[key].default: claims.erase(key)
	for key in self.prison_claims:
		if prison_claims[key].default: prison_claims.erase(key)

	for key in defaults.claims.keys():
		var stripped_key = key.split("_", false, 2)[1]

		var claim = defaults.claims[key]
		claim.is_claimed = 1 if claim.faction == "Claimed" else 0
		claim.notes = claim.notes if "notes" in claim else ""
		claim.default = true
		if claim.class == crew_type:
			if not (stripped_key in self.claims.keys()) or self.claims[stripped_key].default:
				self.claims[stripped_key] = claim

		elif claim.class == "prison":
			if not (stripped_key in self.prison_claims.keys()) or self.prison_claims[stripped_key].default:
				self.prison_claims[stripped_key] = claim

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
			var self_property = get(property)
			self_property[key] = new_property


func get_defaults(json_file_path: String):
	var file = File.new()
	if not file.file_exists(json_file_path):
		print("ERROR IN GET DEFAULTS PLAYBOOK")
		print("unable to find json file: " + json_file_path)
	file.open(json_file_path, File.READ)
	var data = parse_json(file.get_as_text())
	return data


func setup(json_or_file_path_to_json, crew_type: String, overwrite:bool = false)-> void:
	if not needs_setup and not overwrite: return
	.setup(json_or_file_path_to_json, crew_type, overwrite)
	var srd: Dictionary = {}
	srd = get_defaults(json_or_file_path_to_json) if json_or_file_path_to_json is String else json_or_file_path_to_json

	needs_setup = false
	crew_type = crew_type.to_lower()
	experience.clear()
	experience["playbook"] = 0

	type = crew_type
	setup_property("abilities", srd, "crew_abilities")
	setup_property("upgrades", srd, "crew_upgrades")
	setup_property("contacts", srd)
	setup_claims(srd, crew_type)
