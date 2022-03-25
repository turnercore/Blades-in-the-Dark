extends ColorRect

var connections:Array
var has_full_connection:bool = false
var has_partial_connection:bool = false
export var active: bool = true setget _set_active


signal partially_connected
signal fully_disconnected


func _process(_delta: float) -> void:
	check_connections()


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




func _set_active(value: bool) -> void:
	active = value

	if active:
		modulate = Color.white
	else:
		modulate = Color(0, 0, 0, 0)

	check_connections()


func _on_neighbor_toggled(_button_pressed:bool)->void:
	check_connections()
