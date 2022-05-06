class_name PCConstructor
extends Reference


#Builds the dictonary from the default data and the SRD data
func build(pc_type:String, srd:Dictionary)-> Dictionary:
	var data:= {
		id = "",
		PLAYBOOK_TYPE = "player",
		version = ProjectSettings.get_setting("application/config/version"),
		name = "",
		type = pc_type,
		stats = get_stats(srd, pc_type),
		abilities = {},
		coin = {
			"max": 4,
			"available" : 0,
			"stash" : 0
		},
		experience = {
			"playbook": 0,
			"insight": 0,
			"prowess": 0,
			"resolve": 0,
		},
		equipped_items = [],
		normal_armor = false,
		heavy_armor = false,
		special_armor = false,
		lifestyle = "",
		harms = {
			level_1 = [null, null],
			level_2 = [null, null],
			level_3 = [null]
		},
		current_load = 3,
		vice = {
			name = "",
			type = "",
			purveyor = "",
			description = ""
		},
		contacts = {},
		xp_gains = get_xp_gain(srd, pc_type),
		traumas = [],
		heal_clock = {},
		items = get_items(srd, pc_type),
		stress = 0,
		background = {
			"name": "",
			"description": "",
			"notes" : ""
		},
		heritage = {
			"name":"",
			"description":"",
			"notes": ""
		},
		look = "",
		alias = "",
		notes = ""
	}

	return data

func get_xp_gain(srd:Dictionary, type:String)-> Array:
	var xp_gains: = []
	var srd_xp_gains:Array = srd.xp_gain
	for gain in srd_xp_gains:
		if gain.class == type.to_lower() or gain.class == "all":
			xp_gains.append(gain.description)
	return xp_gains

func get_friends_foes(srd:Dictionary, type:String)-> Dictionary:
	var friends_and_foes: = {}
	var srd_contacts = srd.contacts
#		name, description,class,claimed
	for name in srd_contacts:
		var contact = srd_contacts[name]
		if contact["types"].has("all") or contact["types"].has(type.to_lower()):
			friends_and_foes[name] = contact
	return friends_and_foes

func get_items(srd:Dictionary, type:String)-> Dictionary:
	var items: = {}
	var srd_items = srd.items
#		name, description,class,claimed
	for name in srd_items:
		var item = srd_items[name]
		if item["class"] == "all" or item["class"] == type:
			items[name] = item
	return items

func get_abilities(srd:Dictionary, type:String)-> Dictionary:
	var abilities: = {}
	var srd_abilities = srd.character_abilities
#		name, description,class,claimed
	for name in srd_abilities:
		var ability = srd_abilities[name]
		if ability["class"].to_lower() == "all" or ability["class"].to_lower() == type.to_lower():
			abilities[name] = ability
	return abilities

func get_stats(srd:Dictionary, type:String) -> Dictionary:
	var actions = srd.actions
	var stats:Dictionary = actions.duplicate(true)
	var pc_type = srd.pc_types[type]

	for name in actions:
		var action = actions[name]
		stats[name]["level"] = srd.pc_types[type][name]
	return stats
