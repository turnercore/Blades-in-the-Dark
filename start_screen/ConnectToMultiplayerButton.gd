extends Button

export (PackedScene) var multiplayer_login_scene
export (PackedScene) var match_list_scene

export (bool) var on_start_screen: = false

func _on_ConnectToMultiplayerButton_pressed() -> void:
	disabled = true
	if not ServerConnection.is_connected_to_server:
		Events.popup(multiplayer_login_scene, true)
		yield(ServerConnection, "server_connected")
		yield(get_tree(), "idle_frame")
		Events.popup(match_list_scene, true)
		yield(ServerConnection, "match_joined")
		yield(get_tree(), "idle_frame")
		if on_start_screen:
			get_tree().change_scene_to(Globals.GAME_SCENE)
	else:
		Events.popup(match_list_scene, true)
	disabled = false
