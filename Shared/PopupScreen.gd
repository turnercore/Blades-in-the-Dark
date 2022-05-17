class_name PopupScreen
extends Control

#signal popup_hide

func _ready() -> void:
	visible = false
	set_process_input(false)
	set_process(false)
	set_process_unhandled_input(false)
	set_process_unhandled_key_input(false)
	set_process_internal(false)


func popup()-> void:
	visible = true
	set_process_input(true)
	set_process(true)
	set_process_unhandled_input(true)
	set_process_unhandled_key_input(true)
	set_process_internal(true)


func show()-> void:
	popup()


func hide()-> void:
	visible = false
	set_process_input(false)
	set_process(false)
	set_process_unhandled_input(false)
	set_process_unhandled_key_input(false)
	set_process_internal(false)
#	emit_signal("popup_hide")
	Events.emit_signal("popup_finished")


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().set_input_as_handled()
		hide()
