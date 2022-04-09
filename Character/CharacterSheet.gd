extends Control

const defaults_json: = 'res://srd/default_srd.json'

export (Resource) var playbook setget _set_playbook

onready var abilities: = $"PanelContainer/Skills/Special Abilities"
onready var character_equipment: = $PanelContainer/Equipment/CharacterEquipment

func _ready() -> void:
	Events.connect("character_changed", self, "_on_character_changed")



func setup()-> void:
	if not playbook: return
	abilities.setup(playbook)
	character_equipment.setup(playbook)


func propagate_set_playbook_recursive(node: Node)-> void:
	if "playbook" in node and node != self:
		node.set("playbook", playbook)
	for child in node.get_children():
		propagate_set_playbook_recursive(child)


func _on_character_changed(character_playbook: PlayerPlaybook)-> void:
	self.playbook = character_playbook


func _set_playbook(value: PlayerPlaybook)-> void:
	playbook = value
	propagate_set_playbook_recursive(self)


