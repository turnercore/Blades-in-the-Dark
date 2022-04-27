extends Button

export (PackedScene) var crew_setup_sceen
export (bool) var on_start_screen: = false
var new_game_node:Node


func show_crew_setup()->void:
	var crew_setup_popup = crew_setup_sceen.instance()
	crew_setup_popup.on_start_screen = true
	Events.popup(crew_setup_popup)


func _on_CreateNewCrewButton_pressed() -> void:
	if on_start_screen:
		print("waiting for save_loaded sig")
		yield(GameSaver, "save_loaded")
		print("got save_loaded sig")
	show_crew_setup()
