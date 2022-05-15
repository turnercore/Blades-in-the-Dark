extends Button


func _process(_delta: float) -> void:
	text = "Save Game (ID: " + GameSaver.current_save_id + ")"


func _on_SaveButton_pressed() -> void:
	GameData.save_game()
