extends Button

onready var popup: = $EditMapDialog

func _on_EditMap_pressed() -> void:
	popup.popup()
