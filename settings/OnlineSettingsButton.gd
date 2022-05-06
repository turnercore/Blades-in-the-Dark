extends Button

export (PackedScene) var online_settings_scene

func _on_OnlineSettingsButton_pressed() -> void:
	var online_settings_instance = online_settings_scene.instance()
	Events.popup(online_settings_instance)
