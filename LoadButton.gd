extends Button
export (PackedScene) var load_screen

func _on_LoadButton_pressed() -> void:
	Events.popup(load_screen)
