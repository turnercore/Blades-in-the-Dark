class_name SaveGame
extends Resource

export (String) var version: String = ''

export (Dictionary) var data: Dictionary = {}

export (Resource) var crew_playbook = CrewPlaybook.new() setget _set_crew_playbook

export (Array, Resource) var pc_playbooks

export (Dictionary) var map: = {
	"name": "Duskvol",
	Vector2(100,50): "Test Map Note"
}

var needs_setup:bool = true

signal save_updated


func setup()->void:
	needs_setup = false
	for playbook in pc_playbooks:
		if playbook.has_signal("property_changed"):
			playbook.connect("property_changed", self, "_on_playbook_update")
	if crew_playbook.has_signal("property_changed"):
		crew_playbook.connect("property_changed", self, "_on_playbook_update")


func add_pc_playbook(playbook:Playbook)-> void:
	pc_playbooks.append(playbook)
	emit_changed()


func remove_pc_playbook(playbook:Playbook)-> void:
	if playbook in pc_playbooks:
		pc_playbooks.erase(playbook)
		emit_changed()


func _set_crew_playbook(playbook:CrewPlaybook)->void:
	crew_playbook = playbook
	emit_changed()


func _on_playbook_update(_property_changed)-> void:
	emit_changed()
