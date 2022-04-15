class_name Field
extends Control

export (String) var FIELD_TEMPLATE:= "%s"
var playbook:Playbook setget _set_playbook
var id setget _set_id

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _set_playbook(new_playbook:Playbook)-> void:
	playbook = new_playbook
	Globals.propagate_set_playbook_recursive(self, new_playbook, self)


func _set_id(value:String)-> void:
	id = value.c_escape().to_lower().replace(" ", "_")
	Globals.propagate_set_playbook_fields_recursive(self, FIELD_TEMPLATE%id)
