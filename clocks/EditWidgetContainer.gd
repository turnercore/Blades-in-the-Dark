extends VBoxContainer


#func _ready() -> void:
#	visible = false

func _on_EditButton_toggled(button_pressed: bool) -> void:
	visible = button_pressed
