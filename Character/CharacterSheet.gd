extends PopupScreen

const defaults_json: = 'res://srd/default_srd.json'

export (Resource) var _playbook setget _set_playbook


func _ready() -> void:
	Events.connect("character_selected", self, "_on_character_selected")


func setup(playbook:Playbook)-> void:
	if not playbook: return
	if _playbook != playbook: _playbook = playbook
	Globals.propagate_set_playbook_recursive(self, playbook, self)


func _on_character_selected(character_playbook: PlayerPlaybook)-> void:
	setup(character_playbook)


func _set_playbook(value: PlayerPlaybook)-> void:
	_playbook = value
	setup(_playbook)
