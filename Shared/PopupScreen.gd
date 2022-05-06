class_name PopupScreen
extends Control

signal popup_hide

func _ready() -> void:
	set_process_input(false)


func popup()-> void:
	visible = true
	set_process_input(true)


func hide()-> void:
	visible = false
	set_process_input(false)
	emit_signal("popup_hide")
	Events.emit_signal("popup_finished")


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().set_input_as_handled()
		hide()
