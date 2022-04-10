extends Button


func _on_QuitButton_pressed() -> void:
	GameData.save_all()
	get_tree().notification(MainLoop.NOTIFICATION_WM_QUIT_REQUEST)
