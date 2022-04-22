extends Button

export (PackedScene) var server_test_console




func _on_ServerTestConsoleButton_pressed() -> void:
	var console = server_test_console.instance()
	Events.popup(console)
