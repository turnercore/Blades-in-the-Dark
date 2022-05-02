class_name Field
extends Control

export (String) var FIELD_TEMPLATE:= "%s"
var id setget _set_id
var resource:NetworkedResource

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _set_resource(value:NetworkedResource)-> void:
	resource = value
	Globals.propagate_set_property_recursive(self, "resource", resource)


func _set_id(value:String)-> void:
	id = value.c_escape().to_lower().replace(" ", "_")
	Globals.propagate_set_playbook_fields_recursive(self, FIELD_TEMPLATE%id)
