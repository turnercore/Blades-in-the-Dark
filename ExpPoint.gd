extends TextureButton

#This will control the animations for filling (or resetting) a point
onready var parent: = get_parent()

func _on_ExpPoint_toggled(button_pressed: bool) -> void:
	if button_pressed == true:
		if "filled_points" in parent:
			parent.filled_points += 1
	elif button_pressed == false:
		if "filled_points" in parent:
			parent.filled_points -= 1

func reset()->void:
	pressed = false

func load_set()->void:
	pressed = true
