class_name CrewPlaybook
extends Playbook

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


func setup(json_or_file_path_to_json, crew_type: String, overwrite:bool = false)-> void:
	if not needs_setup and not overwrite: return
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


func _change_type(new_type:String)-> void:
	type = new_type
	if srd_json != "": setup(self.srd_json, new_type)
