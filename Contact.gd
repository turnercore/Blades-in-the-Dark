class_name Contact
extends Field

const MIN_SIZE_COMPACT: = Vector2(200, 25)
const MIN_SIZE_FULL: = Vector2(250, 250)
const MIN_SIZE_NO_EDIT: = Vector2(250, 150)

export (bool) var compact:= false

export (NodePath) onready var contact_full_sized_editable = get_node(contact_full_sized_editable)
export (NodePath) onready var contact_full_sized_static = get_node(contact_full_sized_static)
export (NodePath) onready var contact_compact = get_node(contact_compact)
export (bool) var is_pc:=false
export (bool) var editable: = true

func _ready() -> void:
	if compact:
		contact_full_sized_editable.visible = false
		contact_compact.visible = true
		contact_full_sized_static.visible = false
		rect_min_size = MIN_SIZE_COMPACT
	elif editable:
		contact_full_sized_editable.visible = true
		contact_compact.visible = false
		contact_full_sized_static.visible = false
		rect_min_size = MIN_SIZE_FULL
	else:
		contact_full_sized_static.visible = true
		contact_full_sized_editable.visible = false
		contact_compact.visible = false
		rect_min_size = MIN_SIZE_NO_EDIT

	var formatted_field_template:String = FIELD_TEMPLATE%id if "%s" in FIELD_TEMPLATE else ""
	Globals.propagate_set_playbook_fields_recursive(self, formatted_field_template)

	$contact_full_sized_editable/MarginContainer/HBoxContainer/reputation.visible = not is_pc


func _on_name_mouse_entered() -> void:
	Tooltip.display_tooltip($contact_compact/name.text, $contact_full_sized_editable/description.text)


func _on_contact_compact_mouse_entered() -> void:
	Tooltip.display_tooltip($contact_compact/name.text, $contact_full_sized_editable/description.text)

