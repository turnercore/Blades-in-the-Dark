class_name DragableWindow
extends PanelContainer

var _reset_position = Vector2()
var _previous_mouse_position = Vector2()
var _is_dragging = false

signal on_open
signal on_closed

func _ready():
	_reset_position = rect_position


func _process(delta):
	if _is_dragging:
		var mouse_delta = _previous_mouse_position - get_local_mouse_position()
		rect_position -= mouse_delta


func show():
	emit_signal("on_open")
	rect_position = _reset_position
	visible = true


func hide():
	emit_signal("on_closed")
	visible = false


func _on_close_button_pressed():
	queue_free()


func _on_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("left_click"):
		print("Dragging")
		_is_dragging = true
		_previous_mouse_position = get_local_mouse_position()
	if event.is_action_released("left_click"):
		print("Stop dragging")
		_is_dragging = false
