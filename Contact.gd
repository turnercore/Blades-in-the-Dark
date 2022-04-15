class_name Contact
extends Field

const MIN_SIZE_COMPACT: = Vector2(200, 25)
const MIN_SIZE_FULL: = Vector2(250, 250)

export (bool) var compact:= false

func _ready() -> void:
	if compact:
		$contact_full_sized.visible = false
		$contact_compact.visible = true
		rect_min_size = MIN_SIZE_COMPACT

	else:
		$contact_full_sized.visible = true
		$contact_compact.visible = false
		rect_min_size = MIN_SIZE_FULL
	Globals.propagate_set_playbook_fields_recursive(self, FIELD_TEMPLATE%id)


func _on_name_mouse_entered() -> void:
	Tooltip.display_tooltip($contact_compact/name.text, $contact_full_sized/description.text)


func _on_contact_compact_mouse_entered() -> void:
	Tooltip.display_tooltip($contact_compact/name.text, $contact_full_sized/description.text)

