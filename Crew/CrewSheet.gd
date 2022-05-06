extends PopupScreen

const defaults_json: = 'res://srd/default_srd.json'

var resource:NetworkedResource setget _set_resource


func _ready() -> void:
	if GameData.crew_playbook_resource: self.resource = GameData.crew_playbook_resource
	GameData.connect("crew_changed", self, "_on_crew_changed")


func setup(crew_playbook:NetworkedResource)-> void:
	if not crew_playbook: return
	if resource != crew_playbook: resource = crew_playbook
	Globals.propagate_set_property_recursive(self, "resource", crew_playbook)


func _on_crew_changed(crew_playbook: NetworkedResource)-> void:
	setup(crew_playbook)


func _set_resource(value: NetworkedResource)-> void:
	resource = value
	setup(value)
