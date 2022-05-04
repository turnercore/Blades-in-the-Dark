extends Button

export (PackedScene) var server_test_console

func _ready() -> void:
	self.visible = ProjectSettings.get_setting("debug/settings/debug")


func _on_ServerTestConsoleButton_pressed() -> void:
	var console = server_test_console.instance()
	Events.popup(console)
