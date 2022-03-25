class_name CrewPlaybook
extends Playbook


export (int) var heat: int = 0
export (int) var wanted_level: int = 0
export (String) var reputation
export (Dictionary) var upgrades
export (Dictionary) var lair: = {
	"name" : "",
	"location" : "",
}
export (String) var hunting_grounds
export (Dictionary) var cohorts
export (Dictionary) var claims
export (Dictionary) var prison_claims
export (Dictionary) var map




func setup(json: String, crew_type: String, overwrite:bool = false)-> void:
	needs_setup = false
	crew_type = crew_type.to_lower()
	if experience is Dictionary: experience = 0
	var defaults = get_defaults(json)

	#Have a JSON object with all the default information
	self.type = crew_type
	setup_abilities(defaults, crew_type)
	setup_upgrades(defaults, crew_type)
	setup_contacts(defaults, crew_type)
	setup_claims(defaults, crew_type)


func setup_claims(defaults:Dictionary, crew_type: String)->void:
	for key in defaults.claims.keys():
		var stripped_key = key.split("_", false, 2)[1]
		var claim = defaults.claims[key]
		if claim.class == crew_type:
			self.claims[stripped_key] = claim
		elif claim.class == "prison":
			self.prison_claims[stripped_key] = claim



func setup_contacts(defaults:Dictionary, crew_type: String)->void:
	for key in defaults.contacts.keys():
		var contact = defaults.contacts[key]
		if contact.class == crew_type or contact.class == "all":
			self.contacts[key] = contact



func setup_upgrades(defaults:Dictionary, crew_type: String)->void:
	for key in defaults.crew_upgrades.keys():
		var upgrade = defaults.crew_upgrades[key]
		if upgrade.class == crew_type or upgrade.class == "all":
			self.upgrades[key] = upgrade


func setup_abilities(defaults:Dictionary, crew_type: String)->void:
	for key in defaults.crew_abilities.keys():
		var ability = defaults.crew_abilities[key]
		if ability.class == crew_type or ability.class == "all":
			self.abilities[key] = ability
