extends Control

var is_open:= false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("settings_menu"):
		if is_open:
			visible = false
			is_open = false
		else:
			visible = true
			is_open = true

