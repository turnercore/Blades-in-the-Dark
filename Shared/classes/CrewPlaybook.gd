class_name CrewPlaybook
extends Playbook


export (int) var heat: int = 0
export (int) var wanted_level: int = 0
export (String) var reputation
export (Dictionary) var upgrades
export (Dictionary) var lair: = {
	"name" : "",
	"location" : "",
	"description": ""
}
export (Dictionary) var hunting_grounds: = {
	"location": "",
	"description": ""
}
export (Dictionary) var cohorts
export (Dictionary) var claims
export (Dictionary) var prison_claims
export (Dictionary) var map




func setup(json_or_file_path_to_json, crew_type: String, overwrite:bool = false)-> void:
	if not needs_setup and not overwrite: return

	var json = json_or_file_path_to_json
	var defaults: Dictionary = {}

	needs_setup = false
	crew_type = crew_type.to_lower()
	experience.clear()
	experience["playbook"] = 0


	if json is String:
		defaults = get_defaults(json)
	else:
		defaults = json


	type = crew_type
	setup_abilities(defaults, crew_type, overwrite)
	setup_upgrades(defaults, crew_type)
	setup_contacts(defaults, crew_type)
	setup_claims(defaults, crew_type)


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



func setup_contacts(defaults:Dictionary, crew_type: String)->void:
	#clear defaults if any exist
	for key in self.contacts:
		if contacts[key].default: contacts.erase(key)

	for key in defaults.contacts.keys():
		var contact = defaults.contacts[key]
		contact.default = true
		if contact.class == crew_type or contact.class == "all":
			if not (key in self.contacts.keys()) or self.contacts[key].default:
				self.contacts[key] = contact



func setup_upgrades(defaults:Dictionary, crew_type: String)->void:
	#clear defaults if any exist
	for key in self.upgrades:
		if upgrades[key].default: upgrades.erase(key)

	for key in defaults.crew_upgrades.keys():
		var upgrade = defaults.crew_upgrades[key]
		upgrade.default = true
		if upgrade.class == crew_type or upgrade.class == "all":
			if not (key in self.upgrades.keys()) or self.upgrades[key].default:
				self.upgrades[key] = upgrade


func setup_abilities(defaults:Dictionary, crew_type: String, overwrite: bool = true)->void:
	#clear defaults if any exist
	if overwrite:
		abilities.clear()

	for key in defaults.crew_abilities.keys():
		var esc_key:String = key.strip_edges().to_lower().replace(" ", "_")
		var ability = defaults.crew_abilities[key]
		ability.default = true
		if ability.class == crew_type or ability.class == "all":
			if not (esc_key in self.abilities.keys()) or abilities[esc_key].default:
				self.abilities[esc_key] = ability


func _change_type(new_type:String)-> void:
	type = new_type
	if srd_json != "": setup(self.srd_json, new_type)
