extends Button

export (PackedScene) var multiplayer_login_scene
export (PackedScene) var create_match_scene
export (PackedScene) var choose_game_scene


export (bool) var on_start_screen: = false

func _on_HostGameButton_pressed() -> void:
	disabled = true
	if not ServerConnection.is_connected_to_server:
		#Server isn't connected, so let's get connected
		Events.popup(multiplayer_login_scene, true)
		yield(ServerConnection, "server_connected")
		yield(get_tree(), "idle_frame")
		if not GameData.is_game_setup:
			Events.popup(choose_game_scene, true)
			yield(GameData, "game_setup")
			yield(get_tree(), "idle_frame")
		Events.popup(create_match_scene, true)
		yield(ServerConnection, "match_created")
		yield(get_tree(), "idle_frame")
		if on_start_screen:
			get_tree().change_scene_to(Globals.GAME_SCENE)
	else:
		#Server already connected, handle it this way:
		Events.popup(create_match_scene, true)
	disabled = false
