extends Playbook



var aliases: Array = []
var look: String
var heritage: String
var stress: int = 0
var traumas:Array
var heal_clock:Clock
var items:Dictionary
var vice:String
var xp_gain: String
var friends_and_foes: Dictionary
var vice_purveyors: Array
var current_load:int = 3
var harms: Array
var equipped_items: Array
var normal_armor: bool = false
var heavy_armor: bool = false
var speical_armor: bool = false


func setup(json: String, player_class: String, overwrite:bool = false)-> void:
	needs_setup = false
	player_class = player_class.to_lower()
	experience = {
		"playbook": 0,
		"insight" : 0,
		"prowess" : 0,
		"resolve" : 0
	}
	var defaults = get_defaults(json) as Dictionary
	self.type = player_class

	setup_abilities(defaults, player_class)
	setup_items(defaults, player_class)
	setup_friends_and_foes(defaults, player_class)
	setup_xp_gain(defaults, player_class)
	setup_vice_purveyors(defaults, player_class)

	set_starting_stats(player_class)


func set_starting_stats(player_class: String)->void:
	match player_class:
		"cutter":
			stats.prowess.skirmish = 2
			stats.resolve.command = 1
		"hound":
			stats.insight.hunt = 2
			stats.insight.survey = 1
		"leech":
			stats.insight.tinker = 2
			stats.prowess.wrek = 1
		"lurk":
			stats.prowess.finesse = 1
			stats.prowess.prowl = 2
		"slide":
			stats.resolve.consort = 1
			stats.resolve.sway = 2
		"spider":
			stats.insight.study = 1
			stats.resolve.consort = 2
		"whisper":
			stats.insight.study = 1
			stats.resolve.attune = 2
		"_":
			pass

	insight = get_insight()
	prowess = get_prowess()
	resolve = get_resolve()


func setup_vice_purveyors(defaults:Dictionary, player_class: String)->void:
	for key in defaults.vice_purveyors.keys():
		var purveyor = defaults.vice_purveyors[key]
		purveyor.name = key
		self.vice_purveyors.append(purveyor)


func setup_xp_gain(defaults:Dictionary, player_class: String)->void:
	for key in defaults.xp_gain.keys():
		if key == player_class:
			xp_gain = str(key)
			return


func setup_friends_and_foes(defaults:Dictionary, player_class: String)->void:
	for key in defaults.friends_foes.keys():
		var person = defaults.friends_foes[key]
		if person.class == player_class or person.class == "all":
			self.friends_and_foes[key] = person


func setup_abilities(defaults:Dictionary, player_class: String)->void:
	for key in defaults.character_abilities.keys():
		var ability = defaults.character_abilities[key]
		if ability.class == player_class or ability.class == "all":
			self.abilities[key] = ability


func setup_items(defaults:Dictionary, player_class: String)->void:
	for key in defaults.items.keys():
		var item = defaults.items[key]
		if item.class == player_class or item.class == "all":
			self.items[key] = item
