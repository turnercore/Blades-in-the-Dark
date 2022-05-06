extends Button

export (PackedScene) var load_screen
export (bool) var on_start_screen: = false
func _on_LoadButton_pressed() -> void:
	var load_screen_instance = load_screen.instance()
	load_screen_instance.on_start_screen = on_start_screen
	Events.popup(load_screen_instance)
