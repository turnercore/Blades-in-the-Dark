extends Area2D

export (String, MULTILINE) var info_text


func _on_mouse_entered(_area = null) -> void:
	if not info_text:
		return
	Events.emit_signal("info_broadcasted", info_text)
	self.modulate.a = 1


func _on_mouse_exited(_area = null) -> void:
	Events.emit_signal("info_broadcasted", "")
	self.modulate.a = 0.33



func _on_MapNote_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event.is_action_pressed("left_click"):
		print("left click on note" + info_text)
