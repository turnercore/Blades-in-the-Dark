extends Control

const defaults_json: = 'res://srd/default_srd.json'

export (Resource) onready var playbook = playbook as PlayerPlaybook setget _set_playbook

onready var abilities: = $"PanelContainer/Skills/Special Abilities"
onready var character_equipment: = $PanelContainer/Equipment/CharacterEquipment

func _ready() -> void:
	Events.connect("character_changed", self, "_on_character_changed")
	GameSaver.connect("game_loaded", self, "_on_game_loaded")


func setup()-> void:
	abilities.setup(playbook)
	character_equipment.setup(playbook)


func propogate_set_playbook_recursive(node: Node)-> void:
	if "playbook" in node and node != self:
		node.set("playbook", playbook)
	for child in node.get_children():
		propogate_set_playbook_recursive(child)


func _on_character_changed(character_playbook: PlayerPlaybook)-> void:
	self.playbook = character_playbook


func _set_playbook(value: PlayerPlaybook)-> void:
	playbook = value
	propogate_set_playbook_recursive(self)


func _on_game_loaded()->void:
	pass

