#This AutoLoad handles routing NetworkTraffic as well as custom send requests,
#I made this to seperate out the logic from the ServerConnection class so the ServerConnection class
#can be more generalized and reused in different projects

extends Node

enum OP_CODES {
	PLAYER_MOVEMENT,
	PLAYER_SPRITE,
	GAMEDATA_LOCATION_CREATED,
	GAMEDATA_LOCATION_REMOVED,
	GAMEDATA_LOCATION_UPDATED,
	GAMEDATA_GAME_STATE_CHANGED,
	GAMEDATA_PC_PLAYBOOK_CREATED,
	GAMEDATA_PLAYBOOK_REMOVED,
	GAMEDATA_PLAYBOOK_UPDATED,
	GAMEDATA_CREW_PLAYBOOK_CREATED,
	GAMEDATA_CLOCK_CREATED,
	GAMEDATA_CLOCK_REMOVED,
	GAMEDATA_CLOCK_UPDATED,
	CURRENT_GAME_STATE_REQUESTED = 100,
	CURRENT_GAME_STATE_BROADCAST = 101
}

signal player_movement_recieved(user_id, pos)
signal player_sprite_changed(user_id, sprite)
signal gamedata_location_created(note_data)
signal gamedata_location_updated(note_data)
signal gamedata_location_removed(note_data)
signal gamedata_game_state_changed(game_state)
signal gamedata_pc_playbook_created(playbook)
signal gamedata_crew_playbook_created(playbook)
signal gamedata_playbook_removed(playbook)
signal gamedata_playbook_updated(id, type, field, value)
signal gamedata_clock_created(clock)
signal gamedata_clock_removed(clock_id)
signal gamedata_clock_updated(clock)
signal current_game_state_requested(user_id)
signal inital_game_state_recieved(data)
signal gamedata_recieved(data)


func _ready() -> void:
	ServerConnection.connect("match_state_recieved", self, "_on_match_state_recieved")
	ServerConnection.connect("chat_message_received", self, "_on_chat_message_recieved")


#func send_rpc_async(rpc:String, op_code:int, data)-> int:
#	var payload: = {}
#	payload["rpc"] = rpc
#	payload["data"] = JSON.print(data)
#	var result:int
#	var json_data = JSON.print(payload)
#	result = yield(ServerConnection.send_match_state_async(op_code, payload), "completed")
#	return result


func send_data_async(op_code:int, data)-> int:
	var result:int
	result = yield(ServerConnection.send_match_state_async(op_code, data), "completed")
	return result


#-------------------Recieving Data-----------------------------
func _on_match_state_recieved(match_state: NakamaRTAPI.MatchData)-> void:
	#match_state Schema:
#		"match_id": {"name": "match_id", "type": TYPE_STRING, "required": true},
#		"presence": {"name": "presence", "type": "UserPresence", "required": false},
#		"op_code": {"name": "op_code", "type": TYPE_STRING, "required": false},
#		"data": {"name": "data", "type": TYPE_STRING, "required": false}

	#The op code that was sent with the data
	var op_code:int = int(match_state.op_code)
	#The user/presence that sent the data
	var presence:NakamaRTAPI.UserPresence = match_state.presence
	#the match_id for the data, could provide a security check since there should only be one match
	var match_id:String = match_state.match_id
	#The data sent, unpacked
	var json_parsed_data:JSONParseResult = JSON.parse(match_state.data)
	var data

	if json_parsed_data.error == OK:
		data = json_parsed_data.result
	else:
		print("ERROR PARSING JSON IN INCOMING MATCH STATE REQUEST")
		print(match_state)
		print("--------------------------------------------------")

	match op_code:
		OP_CODES.PLAYER_MOVEMENT:
			if not data is Dictionary:
				print("Incorrectly formatted data sent for player movement")
			else:
				update_player_movement(data)
		OP_CODES.PLAYER_SPRITE:
			if not data is Dictionary:
				print("Incorrectly formatted data sent for player sprite")
			else:
				update_player_sprite(data)
		OP_CODES.GAMEDATA_LOCATION_CREATED:
			if not data is Dictionary:
				print("Incorrectly formatted data sent for adding a map location")
			else:
				emit_signal("gamedata_location_created", data)
		OP_CODES.GAMEDATA_LOCATION_REMOVED:
			var pos:Vector2 = Globals.str_to_vec2(data)
			if not pos or not pos is Vector2:
				print("incorrect data for removing map location")
			else:
				emit_signal("gamedata_location_removed", pos)
		OP_CODES.GAMEDATA_LOCATION_UPDATED:
			if not data is Dictionary:
				print("Incorrectly formatted data sent for changing a map location")
			else:
				emit_signal("gamedata_location_updated", data)
		OP_CODES.GAMEDATA_GAME_STATE_CHANGED:
			if not data is String:
				print("Incorrectly formatted game state data")
			else:
				emit_signal("gamedata_game_state_changed", data)
		OP_CODES.GAMEDATA_PC_PLAYBOOK_CREATED:
			print("trying to create a new playbook based on data")
			if not data is String:
				print("incorrectly formatted data for playbook creation")
			else:
				var playbook:PlayerPlaybook= PlayerPlaybook.new()
				playbook.load_from_json(data)
				emit_signal("gamedata_pc_playbook_created", playbook)
		OP_CODES.GAMEDATA_PLAYBOOK_REMOVED:
			pass
		OP_CODES.GAMEDATA_PLAYBOOK_UPDATED:
			if not data is Dictionary or not "id" in data or not "type" in data or not "field" in data or not "value" in data:
				print("Incorrectly formatted data sent for updating playbook")
			else:
				var id:String = data.id
				var type:String = data.type
				var field:String = data.field
				var value = data.value
				emit_signal("gamedata_playbook_updated", id, type, field, value)
		OP_CODES.GAMEDATA_CLOCK_CREATED:
			if not data is Dictionary:
				print("Incorrectly formatted data sent as clock")
			else:
				var clock: = Clock.new()
				clock.setup_from_data(data)
				emit_signal("gamedata_clock_created", clock)
		OP_CODES.GAMEDATA_CLOCK_REMOVED:
			if data is String or data is int or data is float:
				emit_signal("gamedata_clock_removed", str(data))
		OP_CODES.GAMEDATA_CLOCK_UPDATED:
			if not data is Dictionary:
				print("Incorrectly formatted data sent as clock")
			else:
				var clock: = Clock.new()
				clock.setup_from_data(data)
				emit_signal("gamedata_clock_updated", clock)
		OP_CODES.GAMEDATA_CREW_PLAYBOOK_CREATED:
			if not data is String:
				print("incorrectly formatted data for crew playbook creation")
			else:
				var playbook:= CrewPlaybook.new()
				playbook.load_from_json(data)
				emit_signal("gamedata_crew_playbook_created", playbook)
		OP_CODES.CURRENT_GAME_STATE_REQUESTED:
			if ServerConnection.is_host:
				emit_signal("current_game_state_requested", data)
			else:
				print("heard request for game state, ignoring because not host")
		OP_CODES.CURRENT_GAME_STATE_BROADCAST:
			if not data is Dictionary:
				print("data for intial game state is incorreclty formatted")
			else:
				emit_signal("inital_game_state_recieved", data)


func update_player_movement(data: Dictionary)-> void:
	if not "pos" in data or not "user_id" in data:
		print("Incorrect data sent for player Movement")
		return

	var pos:Vector2 = Globals.str_to_vec2(data.pos)
	var user_id:String = data.user_id

	emit_signal("player_movement_recieved", user_id, pos)


func update_player_sprite(data: Dictionary)-> void:
	if not "sprite" in data or not "user_id" in data:
		print("Incorrectly formatted data sent for Player Sprite Update")
		return

	var sprite:String = data.sprite
	var user_id:String = data.user_id

	emit_signal("player_sprite_changed", user_id, sprite)
