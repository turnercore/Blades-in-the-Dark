class_name PlayerPlaybook
extends Playbook


export var player_class: String
export var aliases: String
export var look: String
export var heritage: String
export var stress: int = 0
export var trauma_level: int = 0
export var traumas:Array
var heal_clock:Clock
export var items:Dictionary
export var vice:String
export var xp_gain: String
export var friends_and_foes: Dictionary
export var vice_purveyors: Array
export var current_load:int = 3
export var harms: = {
	"level_3": null,
	"level_2": [null, null],
	"level_1": [null, null]
}
export var equipped_items: Array
export var normal_armor: bool = false
export var heavy_armor: bool = false
export var speical_armor: bool = false
export var crew_name:String = ""


func setup(json: String, pc_class: String, overwrite:bool = false)-> void:
	if not needs_setup: return

	needs_setup = false
	pc_class = pc_class.to_lower()
	player_class = pc_class
	experience = {
		"playbook": 0,
		"insight" : 0,
		"prowess" : 0,
		"resolve" : 0
	}
	var defaults = get_defaults(json) as Dictionary
	self.type = pc_class

	setup_abilities(defaults, pc_class)
	setup_items(defaults, pc_class)
	setup_friends_and_foes(defaults, pc_class)
	setup_xp_gain(defaults, pc_class)
	setup_vice_purveyors(defaults, pc_class)
	set_starting_stats(pc_class)



func set_starting_stats(pc_class: String)->void:
	match pc_class:
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


func setup_vice_purveyors(defaults:Dictionary, pc_class: String)->void:
	for key in defaults.vice_purveyors.keys():
		var purveyor = defaults.vice_purveyors[key]
		purveyor.name = key
		self.vice_purveyors.append(purveyor)


func setup_xp_gain(defaults:Dictionary, pc_class: String)->void:
	for key in defaults.xp_gain.keys():
		if key == pc_class:
			xp_gain = str(key)
			return


func setup_friends_and_foes(defaults:Dictionary, pc_class: String)->void:
	for key in defaults.friends_foes.keys():
		var esc_key:String = key.strip_edges().to_lower().replace(" ", "_")
		var person = defaults.friends_foes[key]
		if person.class == pc_class or person.class == "all":
			self.friends_and_foes[esc_key] = person


func setup_abilities(defaults:Dictionary, pc_class: String)->void:
	for key in defaults.character_abilities.keys():
		var esc_key:String = key.strip_edges().to_lower().replace(" ", "_")
		var ability = defaults.character_abilities[key]
		if ability.class == pc_class or ability.class == "all":
			self.abilities[esc_key] = ability


func setup_items(defaults:Dictionary, pc_class: String)->void:
	for key in defaults.items.keys():
		var item: = {
			"name" : "",
			"description" : "",
			"load" : 0,
			"using" : false
		}
		var esc_key:String = key.strip_edges().to_lower().replace(" ", "_")
		item.name = key
		item.load = defaults.items[key].load
		item.description = defaults.items[key].description
		if defaults.items[key].class == pc_class or defaults.items[key].class == "all":
			self.items[esc_key] = item


func set_items(key:String, value:Dictionary)->void:
	var esc_key:String = key.strip_edges().to_lower().replace(" ", "_")
	items[esc_key] = value
	emit_signal("property_changed", "items")
