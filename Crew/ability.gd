class_name Ability
extends VBoxContainer

const PLAYBOOK_FIELD_TEMPLATE: = "abilities.%s"

var playbook:Playbook setget _set_playbook

onready var ability_field: = $HBoxContainer/ability
onready var effect_field: = $effect
onready var claimed_field: = $HBoxContainer/claimed

var ability: String = "" setget _set_ability
var effect: String = ""
var claimed: bool = false


func _ready()-> void:
	ability_field.playbook_field = PLAYBOOK_FIELD_TEMPLATE % ability + ".ability"
	effect_field.playbook_field = PLAYBOOK_FIELD_TEMPLATE % ability + ".effect"
	claimed_field.playbook_field = PLAYBOOK_FIELD_TEMPLATE % ability + ".claimed"


func setup(new_playbook:Playbook)-> void:
	Globals.propagate_set_playbook_recursive(self, new_playbook, self)



func _set_playbook(new_playbook:Playbook)-> void:
	playbook = new_playbook
	setup(new_playbook)


func _set_ability(value:String)-> void:
	ability = value.to_lower().replace(" ", "_")
	ability_field.playbook_field = PLAYBOOK_FIELD_TEMPLATE % ability + ".ability"
	effect_field.playbook_field = PLAYBOOK_FIELD_TEMPLATE % ability + ".effect"
	claimed_field.playbook_field = PLAYBOOK_FIELD_TEMPLATE % ability + ".claimed"
