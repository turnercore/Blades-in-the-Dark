extends Control

const defaults_json: = 'res://srd/default_srd.json'

export (Resource) var playbook setget _set_playbook

onready var abilities: = $"PanelContainer/Skills/Special Abilities"
onready var character_equipment: = $PanelContainer/Equipment/CharacterEquipment

func _ready() -> void:
	Events.connect("character_selected", self, "_on_character_selected")
	if GameData.active_pc:
		self.playbook = GameData.active_pc
		setup()


func setup()-> void:
	if not playbook: return
	abilities.setup(playbook)
	character_equipment.setup(playbook)


func _on_character_selected(character_playbook: PlayerPlaybook)-> void:
	self.playbook = character_playbook


func _set_playbook(value: PlayerPlaybook)-> void:
	playbook = value
	Globals.propagate_set_playbook_recursive(self, playbook, self)


