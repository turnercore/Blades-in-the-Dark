#This AutoLoad handles routing NetworkTraffic as well as custom send requests,
#I made this to seperate out the logic from the ServerConnection class so the ServerConnection class
#can be more generalized and reused in different projects

extends Node

enum OP_CODES {
	PLAYER_MOVEMENT,
	PLAYER_SPRITE,
	PLAYER_PING,
	NETWORKED_RESOURCE_CREATED,
	NETWORKED_RESOURCE_REMOVED,
	NETWORKED_RESOURCE_UPDATED,
	GAMEDATA_GAME_STATE_UPDATED,
	ROLL_RESULT,
	CURRENT_GAME_STATE_REQUESTED,
	JOIN_MATCH_PLAYER_PLAYBOOK_RECIEVED,
	JOIN_MATCH_CREW_PLAYBOOK_RECEIVED,
	JOIN_MATCH_MAP_RECEIVED,
	JOIN_MATCH_SRD_RECIEVED,
	JOIN_MATCH_CLOCKS_RECIEVED,
	JOIN_MATCH_CONTACT_RECIEVED,
	JOIN_MATCH_FACTION_RECIEVED,
	JOIN_MATCH_LOCATION_RECIEVED,
	MATCH_DATA_ALL_SENT,
	PLAYER_DATA_REQUEST,
	PLAYER_DATA_SENT
}

var online: = false

signal networked_resource_created(data)
signal networked_resource_removed(data)
signal networked_resource_updated(data)
signal player_movement_recieved(user_id, pos)
signal player_sprite_changed(user_id, sprite)
signal gamedata_game_state_updated(game_state)
signal current_game_state_requested(user_id)
signal current_game_state_broadcast(data, op_code)
signal gamedata_recieved(data)
signal player_pinged(data)


func _ready() -> void:
	ServerConnection.connect("match_state_recieved", self, "_on_match_state_recieved")
	ServerConnection.connect("chat_message_received", self, "_on_chat_message_recieved")


func send_data_async(op_code:int, data)-> int:
	var result:int
	result = yield(ServerConnection.send_match_state_async(op_code, var2str(data)), "completed")
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
		if json_parsed_data.result is String:
			data = str2var(json_parsed_data.result)
		else:
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
		OP_CODES.GAMEDATA_GAME_STATE_UPDATED:
			if not data is String:
				print("Incorrectly formatted game state data")
			else:
				emit_signal("gamedata_game_state_updated", data)
		OP_CODES.CURRENT_GAME_STATE_REQUESTED:
			if ServerConnection.is_host:
				emit_signal("current_game_state_requested", data)
			else:
				print("heard request for game state, ignoring because not host")
		#GameData takes care of sorting these op codes for initial game setup
		OP_CODES.JOIN_MATCH_SRD_RECIEVED, OP_CODES.JOIN_MATCH_MAP_RECEIVED, OP_CODES.JOIN_MATCH_CLOCKS_RECIEVED, OP_CODES.JOIN_MATCH_CREW_PLAYBOOK_RECEIVED,OP_CODES.JOIN_MATCH_PLAYER_PLAYBOOK_RECIEVED, OP_CODES.MATCH_DATA_ALL_SENT,OP_CODES.JOIN_MATCH_CONTACT_RECIEVED,OP_CODES.JOIN_MATCH_FACTION_RECIEVED,OP_CODES.JOIN_MATCH_LOCATION_RECIEVED:
			emit_signal("current_game_state_broadcast", data, op_code)
		OP_CODES.NETWORKED_RESOURCE_UPDATED:
			emit_signal("networked_resource_updated", data)
		OP_CODES.NETWORKED_RESOURCE_CREATED:
			if data is Dictionary:
				if "id" in data and "library" in data:
					emit_signal("networked_resource_created", data)
		OP_CODES.NETWORKED_RESOURCE_REMOVED:
			if data is Dictionary:
				if "id" in data and "library" in data:
					emit_signal("networked_resource_removed", data)
		OP_CODES.PLAYER_PING:
			if data is Dictionary:
				emit_signal("player_pinged", data)
		_:
			print('INVALID OP CODE: ' + str(op_code))


func update_player_movement(data: Dictionary)-> void:
	if not "pos" in data or not "user_id" in data:
		print("Incorrect data sent for player Movement")
		return

	var pos:Vector2 = str2var(data.pos)
	var user_id:String = data.user_id

	emit_signal("player_movement_recieved", user_id, pos)


func update_player_sprite(data: Dictionary)-> void:
	if not "sprite" in data or not "user_id" in data:
		print("Incorrectly formatted data sent for Player Sprite Update")
		return

	var sprite:String = data.sprite
	var user_id:String = data.user_id

	emit_signal("player_sprite_changed", user_id, sprite)
