extends Timer

func save_game() -> void:
	if GameSaver.data_changed:
		GameSaver.save_all()
		GameSaver.data_changed = false
		print("game saved")
	else: return

func _on_SaveTimer_timeout() -> void:
	save_game()
