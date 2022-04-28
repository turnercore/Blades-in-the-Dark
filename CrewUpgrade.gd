class_name CrewUpgrade
extends Field


var description: String = ""
var claimed: bool = false

func _ready()-> void:
	Globals.propagate_set_playbook_fields_recursive(self, "upgrades."+FIELD_TEMPLATE%id)
