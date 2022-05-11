extends Button

onready var menu: = get_parent()
export (PackedScene) var new_game_popup_scene


func _on_NewGameButton_pressed() -> void:
	Events.popup(new_game_popup_scene, true)
