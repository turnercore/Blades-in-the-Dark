extends PopupScreen

const defaults_json: = 'res://srd/default_srd.json'

var resource setget _set_resource


func _ready() -> void:
	Events.connect("character_selected", self, "_on_character_selected")


func setup(playbook:NetworkedResource)-> void:
	if not playbook: return
	if resource != playbook: resource = playbook
	Globals.propagate_set_property_recursive(self, "resource", playbook)



func _on_character_selected(character_playbook: NetworkedResource)-> void:
	setup(character_playbook)


func _set_resource(value: NetworkedResource)-> void:
	resource = value
	setup(resource)
