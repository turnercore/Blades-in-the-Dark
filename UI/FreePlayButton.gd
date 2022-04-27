extends Button



func _on_FreePlayButton_pressed() -> void:
	var game_state: = "Free Play"
	GameData.game_state = game_state
	if ServerConnection.is_connected_to_server:
		var result = yield(NetworkTraffic.send_data_async(NetworkTraffic.OP_CODES.GAMEDATA_GAME_STATE_UPDATED, game_state), "completed")
		if result != OK:
			print("error sending game state update")
