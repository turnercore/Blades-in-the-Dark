extends HBoxContainer

onready var toggle: = $EditableButton
onready var children: = get_children()

func _ready() -> void:
	toggle.pressed = false

func _on_toggle_edit(toggle_value:bool)->void:
	for child in children:
		if child == toggle: continue
		else: child.visible = toggle_value
