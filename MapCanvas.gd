extends CanvasLayer

var visible: = false setget _set_visible

func _set_visible(value: bool)-> void:
	visible = value
	for child in get_children():
		child.visible = value
