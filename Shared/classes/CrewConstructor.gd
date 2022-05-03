class_name CrewConstructor
extends Reference


#Builds the dictonary from the default data and the SRD data
func build(crew_type:String, srd:Dictionary)-> Dictionary:
	var data:= {
		id = "",
		version = ProjectSettings.get_setting("application/config/version"),
		name = "",
		type = crew_type,
		heat = 0,
		wanted_level = 0,
		reputation = "",
		reputation_level = 0,
		PLAYBOOK_TYPE = "crew",
		hold_level = 0,
		tier = 0,
		upgrades = get_upgrades(srd, crew_type),
		lair = {
			name = "",
			location = "",
			description = ""
		},
		hunting_grounds = {
			location = "",
			description = ""
		},
		cohorts = {},
		claims = get_claims(srd, crew_type),
		prison_claims = get_prison_claims(srd, crew_type),
		operation_type = "",
		abilities = get_abilities(srd, crew_type),
		contacts = get_contacts(srd, crew_type),
		experience = 0,
		coin = {
			max_coin = 40,
			available = 2
		},
		notes = "",
		clocks = {},
		interested_factions = {}
	}

	return data

func get_upgrades(srd:Dictionary, crew_type:String)-> Dictionary:
	var upgrades: = {}
	var srd_upgrades = srd.crew_upgrades
#		name, description, cost, catagory, class,claimed
	for name in srd_upgrades:
		var upgrade = srd_upgrades[name]
		if upgrade.class.to_lower() == "all" or upgrade.class.to_lower() == crew_type.to_lower():
			upgrades[name] = upgrade
	return upgrades

func get_abilities(srd:Dictionary, crew_type:String)-> Dictionary:
	var abilities: = {}
	var srd_abilities = srd.crew_abilities
#		name, description,class,claimed
	for name in srd_abilities:
		var ability = srd_abilities[name]
		if ability["class"].to_lower() == "all" or ability["class"].to_lower() == crew_type.to_lower():
			abilities[name] = ability
	return abilities

func get_contacts(srd:Dictionary, crew_type:String)-> Dictionary:
	var contacts: = {}
	var srd_contacts = srd.contacts
	#name occupation JA_type relationship notes location description image icon JA_associations	JA_traits JA_tags, region
	for name in srd_contacts:
		var contact:Dictionary = srd_contacts[name]
		if contact.type.has(crew_type):
			contacts[name] = contact
	return contacts


func get_claims(srd:Dictionary, crew_type: String)->Dictionary:
	var claims: = {}
	for key in srd.claims.keys():
		var stripped_key = key.split("_", false, 2)[1]

		var claim = srd.claims[key]
		claim.is_claimed = 1 if claim.faction == "Claimed" else 0
		claim.notes = claim.notes if "notes" in claim else ""
		claim.default = true
		if claim.class == crew_type:
			if not (stripped_key in claims.keys()) or claims[stripped_key].default:
				claims[stripped_key] = claim
	return claims

func get_prison_claims(srd:Dictionary, crew_type: String)->Dictionary:
	var prison_claims: = {}
	for key in srd.claims.keys():
		var stripped_key = key.split("_", false, 2)[1]
		var claim = srd.claims[key]
		claim.is_claimed = 1 if claim.faction == "Claimed" else 0
		claim.notes = claim.notes if "notes" in claim else ""
		claim.default = true
		if claim.class == "prison":
			if not (stripped_key in prison_claims.keys()) or prison_claims[stripped_key].default:
				prison_claims[stripped_key] = claim

	return prison_claims

