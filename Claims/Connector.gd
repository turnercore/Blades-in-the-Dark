class_name ClaimTreeConnector
extends ColorRect

var connections:Array
var has_full_connection:bool = false
var has_partial_connection:bool = false
var active: bool = false setget _set_active


signal partially_connected
signal fully_disconnected


func _ready() -> void:
	self.deactivate()


func _process(_delta: float) -> void:
	if active: check_connections()


func check_connections()->void:
	if not active: return

	var cell1 = connections[0]
	var cell2 = connections[1]

	if cell1.is_claimed and cell2.is_claimed:
		has_partial_connection = true
		has_full_connection = true
		self.modulate = Color.black
		return
	else:
		modulate = Color.white

	if cell1.is_claimed or cell2.is_claimed:
		has_partial_connection = true
		has_full_connection = false
		emit_signal("partially_connected")

	if !cell1.is_claimed and !cell2.is_claimed:
		has_partial_connection = false
		has_full_connection = false
		emit_signal("fully_disconnected")


func activate() ->void:
	active = true
	color = Color.white

func deactivate()-> void:
	active = false
	color = Color(0, 0, 0, 0)


func _set_active(value: bool) -> void:
	if value:
		activate()
	else:
		deactivate()
	check_connections()


func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("right_click"):
		if active: self.deactivate()
		elif not active: self.activate()

func _on_neighbor_toggled(_button_pressed:bool)->void:
	check_connections()
