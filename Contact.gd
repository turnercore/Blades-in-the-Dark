class_name Contact
extends Control

const PLAYBOOK_FIELD_TEMPLATE: = "contacts.%s"
const MIN_SIZE_COMPACT: = Vector2(200, 25)
const MIN_SIZE_FULL: = Vector2(250, 250)

export (bool) var compact:= false
export (Resource) var playbook
export (String) var id setget _set_id


func _ready() -> void:
	if compact:
		$contact_full_sized.visible = false
		$contact_compact.visible = true
		rect_min_size = MIN_SIZE_COMPACT

	else:
		$contact_full_sized.visible = true
		$contact_compact.visible = false
		rect_min_size = MIN_SIZE_FULL

	propagate_set_playbook_fields_recursive(self, PLAYBOOK_FIELD_TEMPLATE%id)


func propagate_set_playbook_fields_recursive(node:Node, field_template:String)-> void:
	for child in node.get_children():
		if "playbook_field" in child:
			if "modular_playbook_field_ending" in child and child.modular_playbook_field_ending:
				child.playbook_field = field_template + child.modular_playbook_field_ending
			else:
				child.playbook_field = field_template
		if child.get_child_count() > 0:
			propagate_set_playbook_fields_recursive(child, field_template)


func _set_playbook(new_playbook:Playbook)-> void:
	playbook = new_playbook
	setup(new_playbook)


func setup(new_playbook:Playbook)-> void:
	Globals.propagate_set_playbook_recursive(self, new_playbook, self)


func _set_id(value:String)-> void:
	id = value.c_escape().to_lower().replace(" ", "_")
	propagate_set_playbook_fields_recursive(self, PLAYBOOK_FIELD_TEMPLATE%id)
