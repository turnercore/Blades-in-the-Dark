extends Button

onready var menu: = get_parent()
export (PackedScene) var new_game_popup_scene


func _on_NewGameButton_pressed() -> void:
	var new_game_popup = new_game_popup_scene.instance()
	Events.popup(new_game_popup)
