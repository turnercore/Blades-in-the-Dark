extends TextureButton

#This will control the animations for filling (or resetting) a point
onready var parent: = get_parent()
var ready: = false

func _ready() -> void:
	ready = true

func _on_ExpPoint_toggled(button_pressed: bool) -> void:
	if not ready: return

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
