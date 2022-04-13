extends Popup

const defaults_json: = 'res://srd/default_srd.json'

export (Resource) var _playbook setget _set_playbook


func _ready() -> void:
	if GameData.crew_playbook: self._playbook = GameData.crew_playbook
	GameData.connect("crew_changed", self, "_on_crew_changed")


func setup(crew_playbook:CrewPlaybook)-> void:
	if not crew_playbook: return
	if _playbook != crew_playbook: _playbook = crew_playbook
	Globals.propagate_set_playbook_recursive(self, crew_playbook, self)


func _on_crew_changed(crew_playbook: CrewPlaybook)-> void:
	setup(crew_playbook)


func _set_playbook(value: CrewPlaybook)-> void:
	_playbook = value
	setup(_playbook)
