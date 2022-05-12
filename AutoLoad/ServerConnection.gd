# Autoloaded class that manages in and out bound messages from the game client to Nakama server.
#
# Anything that has to do with communicating with the server is first sent here, then this class
# delegates work to sub-classes. See [Authenticator], [ExceptionHandler], and [StorageWorker].
#
# As in Nakama, asynchronous methods are named `*_async` and you must use yield to get their return
# value.
#
# For example:
#
# var return_code: int = yield(ServerConnection.login_async(email, password), "completed")
# if return_code == OK:
# 	print("Authenticated")
#
# /!\ About Storage
#
# The value being stored **must** be a JSON dictionary. Trying to store anything else
# will return an empty value when read from storage later.
#
# Being aware of what comes out of `JSON.print` is important; `Color`, for instance,
# comes out as a single string with numbers, not a `Dictionary` with RGBA keys.
#
# Packet layout
#
# Messages sent in and out of the server are described in /docs/packets.md
extends Node


const MAX_REQUEST_ATTEMPTS := 3

## Custom operational codes for state messages. Nakama built-in codes are values lower or equal to
## `0`.
#enum OpCodes {
#	UPDATE_POSITION = 1,
#	UPDATE_INPUT,
#	UPDATE_STATE,
#	UPDATE_JUMP,
#	DO_SPAWN,
#	UPDATE_COLOR,
#	INITIAL_STATE
#}

const KEY: = "uZmEv8khiQSA4og5SYtSeAtD6L9bbsSG"
const HOST : String = "turnercore.games"
#"147.182.249.27"
const PORT : int = 7350
const TIMEOUT: = 3
const CLIENT_SCHEME : String = "https"
const SOCKET_SCHEME : String = "ws"

#

# Emitted when the `presences` Dictionary has changed by joining or leaving clients
signal presences_changed(presences)

#Emitted when the server connects
signal server_connected

# Emitted when the server has sent an updated game state. 10 times per second.
signal state_updated(positions, inputs)


#Chat
# Emitted when the server has received a new chat message into the world channel
signal chat_message_received(sender_id, message)
signal user_joined(user)
signal user_left(user)

# Emitted when the server has received the game state dump for all connected characters
signal initial_state_received(data)

#Emitted when the server has received the match state data
signal match_state_recieved(match_state)

signal match_joined(server_match)
signal match_created

signal server_disconnected

# String that contains the error message whenever any of the functions that yield return != OK
var error_message := "" setget _no_set, _get_error_message

# Dictionary with user_id for keys and NakamaPresence for values.
var presences := {} setget _no_set

# Nakama client through which sessions are created, sockets connected, and storage accessed.
# For development purposes, it's set to the default localhost, as listed in the
# /nakama/docker-compose.yml
var _client := Nakama.create_client(KEY, HOST, PORT, CLIENT_SCHEME) setget _no_set

# Nakama socket through which the live game world is interacted with.
var _socket: NakamaSocket setget _no_set

# The ID of the match the game world is associated with
var _world_id: String setget _no_set

# The ID of the world chat channel
var _channel_id: String setget _no_set

var _exception_handler := ExceptionHandler.new()
var _authenticator := Authenticator.new(_client, _exception_handler)
var _storage_worker: StorageWorker

var _match: NakamaRTAPI.Match

var is_connected_to_server: = false
var is_host: = false

func _enter_tree() -> void:
	pause_mode = Node.PAUSE_MODE_PROCESS
	get_tree().root.get_node("/root/Nakama").pause_mode = Node.PAUSE_MODE_PROCESS


func list_matches_async(authoritative: = false, filter:= "", query:= "")-> NakamaAPI.ApiMatchList:
	if not filter is String:
		error_message = "Error, filter for match list needs to be a string"
		yield(get_tree(), "idle_frame")
		return ERR_INVALID_DATA
	if not query is String:
		error_message = "Error, query for match list needs to be a string"
		yield(get_tree(), "idle_frame")
		return ERR_INVALID_DATA
	if not _client:
		error_message = "No Client"
		yield(get_tree(), "idle_frame")
		return ERR_UNAVAILABLE
	if not _authenticator.session:
		error_message = "No valid session"
		yield(get_tree(), "idle_frame")
		return ERR_UNCONFIGURED

	var list_matches = yield(_client.list_matches_async(_authenticator.session, 0, 12, 100, authoritative, filter, query), "completed")

	return list_matches


func update_display_name_async(display_name:String)-> int:
	var result: = 0
	display_name = display_name.c_escape().strip_escapes().strip_edges()
	if not _socket:
		error_message = "Server not connected."
		yield(get_tree(), "idle_frame")
		return ERR_UNAVAILABLE
	if not _client:
		error_message = "No Client"
		yield(get_tree(), "idle_frame")
		return ERR_UNAVAILABLE

	var update_account = yield(_client.update_account_async(_authenticator.session, null, display_name), "completed")
	result = _exception_handler.parse_exception(update_account)

	return result


#ASYNCHRONOUS coroutine that creates a match on the server and joins it
func create_match_async(match_name:= "")-> int:
	if not _socket:
		error_message = "Socket not connected."
		yield(get_tree(), "idle_frame")
		return ERR_UNAVAILABLE

	var result:int = 0
	var server_match = yield(_socket.create_match_async(), "completed")
	result = _exception_handler.parse_exception(server_match)
	if result == OK:
		_match = server_match
		emit_signal("match_created")
		is_host = true

	return result


func join_match_async(match_id:String)-> int:
	var result:int
	match_id = match_id.strip_edges()

	if not _socket:
		error_message = "Server not connected."
		yield(get_tree(), "idle_frame")
		return ERR_UNAVAILABLE


	var server_match = yield(_socket.join_match_async(match_id), "completed")
	result = _exception_handler.parse_exception(server_match)

	if result == OK:
		_match = server_match
		for presence in server_match.presences:
			presences[presence.user_id] = presence
		emit_signal("match_joined", _match)

	return result


func send_match_state_async(op_code:int, data)-> int:
	var result:int
	var json_data = JSON.print(data)

	if not _socket:
		print("Server not connected")
		yield(get_tree(), "idle_frame")
		return ERR_UNAVAILABLE
	if not _match:
		print("Not connected to a match")
		yield(get_tree(), "idle_frame")
		return ERR_UNAVAILABLE

	var async_result:NakamaAsyncResult = yield(_socket.send_match_state_async(_match.match_id, op_code, json_data), "completed")
	result = _exception_handler.parse_exception(async_result)
	return result


func get_match_id()-> String:
	return _match.match_id if _match else ""


func get_self_username()-> String:
	return str(_match.self_user.username) if _match else ""

# Asynchronous coroutine. Authenticates a new session via email and password, and
# creates a new account when it did not previously exist, then initializes _session.
# Returns OK or a nakama error code. Stores error messages in `ServerConnection.error_message`
func register_async(email: String, password: String, username = null) -> int:
	var result: int = yield(_authenticator.register_async(email, password), "completed")
	if result == OK:
		_storage_worker = StorageWorker.new(_authenticator.session, _client, _exception_handler)
	return result


# Asynchronous coroutine. Authenticates a new session via email and password, but will
# not try to create a new account when it did not previously exist, then
# initializes _session. If a session previously existed in `AUTH`, will try to
# recover it without needing the authentication server.
# Returns OK or a nakama error code. Stores error messages in `ServerConnection.error_message`
func login_async(email: String, password: String) -> int:
	var result: int = yield(_authenticator.login_async(email, password), "completed")
	if result == OK:
		_storage_worker = StorageWorker.new(_authenticator.session, _client, _exception_handler)
	return result


# Asynchronous coroutine. Creates a new socket and connects it to the live server.
# Returns OK or a nakama error number. Error messages are stored in `ServerConnection.error_message`
func connect_to_server_async() -> int:
	_socket = Nakama.create_socket_from(_client)
	if not _socket:
		error_message = "Issiue creating socket from client"
		return ERR_CANT_CREATE

	var result: NakamaAsyncResult = yield(
		_socket.connect_async(_authenticator.session), "completed"
	)
	var parsed_result := _exception_handler.parse_exception(result)

	if parsed_result == OK:
		#warning-ignore: return_value_discarded
		_socket.connect("connected", self, "_on_NakamaSocket_connected")
		#warning-ignore: return_value_discarded
		_socket.connect("closed", self, "_on_NakamaSocket_closed")
		#warning-ignore: return_value_discarded
		_socket.connect("received_error", self, "_on_NakamaSocket_received_error")
		#warning-ignore: return_value_discarded
		_socket.connect("received_match_presence", self, "_on_NakamaSocket_received_match_presence")
		#warning-ignore: return_value_discarded
		_socket.connect("received_match_state", self, "_on_NakamaSocket_received_match_state")
		#warning-ignore: return_value_discarded
		_socket.connect("received_channel_message", self, "_on_NamakaSocket_received_channel_message")
		#warning-ignore: return_value_discarded
		_socket.connect("received_channel_presence", self, "_on_NakamaSocket_recieved_channel_presence")


		is_connected_to_server = true
		emit_signal("server_connected")

	return parsed_result


# Asynchronous coroutine. Leaves chat and disconnects from the live server.
# Returns OK or a nakama error number and puts the error message in `ServerConnection.error_message`
func disconnect_from_server_async() -> int:
	var result: NakamaAsyncResult = yield(_socket.leave_chat_async(_channel_id), "completed")
	var parsed_result := _exception_handler.parse_exception(result)
	if parsed_result == OK:
		result = yield(_socket.leave_match_async(_world_id), "completed")
		parsed_result = _exception_handler.parse_exception(result)
		if parsed_result == OK:
			_reset_data()
			_authenticator.cleanup()
			return OK
		is_connected_to_server = false
		emit_signal("server_disconnected")
	return parsed_result


# Saves the email in the config file.
func save_email(email: String) -> void:
	EmailConfigWorker.save_email(email)


# Gets the last email from the config file, or a blank string if missing.
func get_last_email() -> String:
	return EmailConfigWorker.get_last_email()


# Removes the last email from the config file
func clear_last_email() -> void:
	EmailConfigWorker.clear_last_email()


func get_user_id() -> String:
	if _authenticator.session:
		return _authenticator.session.user_id
	return ""


# Sends a chat message to the server to be broadcast to others in the channel.
# Returns OK, a nakama error message, or ERR_UNAVAILABLE if the socket is not connected.
func send_text_async(text: String) -> int:
	if not _socket:
		yield(get_tree(), "idle_frame")
		return ERR_UNAVAILABLE

	var data := {"msg": text}

	var message_response: NakamaRTAPI.ChannelMessageAck = yield(
		_socket.write_chat_message_async(_channel_id, data), "completed"
	)

	var parsed_result := _exception_handler.parse_exception(message_response)
	if parsed_result != OK:
		emit_signal(
			"chat_message_received", "SYSTEM", "Error code %s: %s" % [parsed_result, error_message]
		)

	return parsed_result


func _get_error_message() -> String:
	return _exception_handler.error_message


# Clears the socket, world id, channel id, and presences
func _reset_data() -> void:
	is_connected_to_server = false
	_socket = null
	_world_id = ""
	_channel_id = ""
	presences.clear()


# Called when the socket was connected.
func _on_NakamaSocket_connected() -> void:
	print("NAKAMASOCKET HAS CONNECTED")


# Called when the socket was closed.
func _on_NakamaSocket_closed() -> void:
	print("NAKAMASOCKET HAS CLOSED")
	_socket = null


# Called when the socket reported an error.
func _on_NakamaSocket_received_error(error: String) -> void:
	error_message = error
	print("NakamaSocket has received an error: %s" % error_message)
	_socket = null


# Called when the server reported presences have changed.
func _on_NakamaSocket_received_match_presence(new_presences: NakamaRTAPI.MatchPresenceEvent) -> void:
	for leave in new_presences.leaves:
		#warning-ignore: return_value_discarded
		presences.erase(leave.user_id)
		emit_signal("user_left", leave)

	for join in new_presences.joins:
		if not join.user_id == get_user_id():
			presences[join.user_id] = join
		emit_signal("user_joined", join)
	emit_signal("presences_changed", presences)


func _on_NakamaSocket_recieved_channel_presence(channel_presences: NakamaRTAPI.ChannelPresenceEvent)-> void:
	#Set up chat channel
	print("Recieved channel presence")
	pass

# Called when the server received a custom message from the server.
func _on_NakamaSocket_received_match_state(match_state: NakamaRTAPI.MatchData) -> void:
	emit_signal("match_state_recieved", match_state)


# Called when the server received a new chat message.
func _on_NamakaSocket_received_channel_message(message: NakamaAPI.ApiChannelMessage) -> void:
	if message.code != 0:
		return

	var content: Dictionary = JSON.parse(message.content).result
	emit_signal("chat_message_received", message.sender_id, content.msg)


# Used as a setter function for read-only variables.
func _no_set(_value) -> void:
	pass


# Helper class to manage functions that relate to local files that have to do with
# authentication or login parameters, such as remembering email.
class EmailConfigWorker:
	const CONFIG := "user://config.ini"

	# Saves the email to the config file.
	static func save_email(email: String) -> void:
		var file := ConfigFile.new()
		#warning-ignore: return_value_discarded
		file.load(CONFIG)
		file.set_value("connection", "last_email", email)
		#warning-ignore: return_value_discarded
		file.save(CONFIG)

	# Gets the last email from the config file, or a blank string.
	static func get_last_email() -> String:
		var file := ConfigFile.new()
		#warning-ignore: return_value_discarded
		file.load(CONFIG)

		if file.has_section_key("connection", "last_email"):
			return file.get_value("connection", "last_email")
		else:
			return ""

	# Removes the last email from the config file.
	static func clear_last_email() -> void:
		var file := ConfigFile.new()
		#warning-ignore: return_value_discarded
		file.load(CONFIG)
		file.set_value("connection", "last_email", "")
		#warning-ignore: return_value_discarded
		file.save(CONFIG)


# Helper class to convert values from the server into Godot values.
class Converter:
	# Converts a string in the format `"r,g,b,a"` to a Color. Alpha is skipped.
	static func color_string_to_color(string: String) -> Color:
		var values := string.replace('"', '').split(",")
		return Color(float(values[0]), float(values[1]), float(values[2]))
