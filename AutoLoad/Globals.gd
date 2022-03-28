extends Node

const SRD = 'res://srd/default_srd.json'
var crew_playbook: CrewPlaybook setget _set_crew_playbook
var popup_layer: CanvasLayer
var roster: Dictionary


func _set_crew_playbook(playbook: CrewPlaybook) -> void:
	crew_playbook = playbook
	Events.emit_crew_loaded(playbook)
