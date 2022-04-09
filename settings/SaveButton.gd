extends Button


func _ready() -> void:
	text += " (ID: " + GameSaver.current_save_id + ")"


func _on_SaveButton_pressed() -> void:
	GameData.save_all()
