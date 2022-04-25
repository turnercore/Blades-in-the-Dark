extends PopupScreen

# Maximum number of times to retry a server request if the previous attempt failed.
const MAX_REQUEST_ATTEMPTS := 3
const DEFAULT_PORT = 80
const MAX_PEERS    = 10
const PLAYER_CURSOR: = "res://Shared/PlayerCursor.tscn"

onready var email: = $PanelContainer/VBoxContainer/login/Email
onready var password: = $PanelContainer/VBoxContainer/login/Password
onready var login_result: = $PanelContainer/VBoxContainer/login/LoginResult
onready var connect_result: = $PanelContainer/VBoxContainer/ConnectToServer/ConnectResult
onready var create_match_name: = $PanelContainer/VBoxContainer/creatematch/CreateMatchName
onready var create_match_result: = $PanelContainer/VBoxContainer/creatematch/CreateMatchResult
onready var join_match_name: = $PanelContainer/VBoxContainer/joinmatch/JoinMatchName
onready var join_match_result: = $PanelContainer/VBoxContainer/joinmatch/JoinMatchResult
onready var send_data: = $PanelContainer/VBoxContainer/transmitdata/data
onready var send_data_result: = $PanelContainer/VBoxContainer/transmitdata/SendDataResult
onready var recieved_data: = $PanelContainer/VBoxContainer/RecievedData
onready var ipv6_text_edit: = $PanelContainer/VBoxContainer/HBoxContainer/ipv6
onready var test_peer_button: = $PanelContainer/VBoxContainer/TestPeerToPeerButton


var _server_request_attempts := 0
remotesync var players: = {}
var player_name: String
var ip_address:String

func _ready() -> void:
	print(IP.get_local_addresses())
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("server_disconnected", self, "_server_disconnect")
	ServerConnection.connect("data_recieved", self, "_on_data_recieved")


# Requests the server to authenticate the player using their credentials.
# Attempts authentication up to `MAX_REQUEST_ATTEMPTS` times.
func authenticate_user_async(login_email: String, login_password: String) -> int:
	var result := -1
	while result != OK:
		if _server_request_attempts == MAX_REQUEST_ATTEMPTS:
			break
		_server_request_attempts += 1
		result = yield(ServerConnection.login_async(login_email, login_password), "completed")

	_server_request_attempts = 0
	return result


func _on_LoginButton_pressed() -> void:
	login_result.text = "logging in..."
	var result:int = yield(authenticate_user_async(email.text, password.text), "completed")
	login_result.text = "Error code %s: %s" % [result, ServerConnection.error_message] if result != OK else "LOGGED IN"


func _on_CreateMatchButton_pressed() -> void:
	create_match_result.text = "establishing server connection..."
	var result: int  =  yield(ServerConnection.create_match_async(), "completed")
	create_match_result.text = "Code %s: %s" % [result, ServerConnection.error_message] if result != OK else "MATCH CREATED! %s" % ServerConnection.get_match_id()


func _on_JoinMatchButton_pressed() -> void:
	join_match_result.text = "attempting to join match..."
	var result:int = yield(ServerConnection.join_match_async(join_match_name.text), "completed")
	join_match_result.text = "Code %s: %s" % [result, ServerConnection.error_message] if result != OK else "MATCH JOINED! %s" %ServerConnection.get_match_id()


func _on_SendDataButton_pressed() -> void:
	var data:String = send_data.text if send_data else $PanelContainer/VBoxContainer/transmitdata/data.text
	var result = yield(ServerConnection.send_match_state_async(0, data),  "completed")
	send_data_result.text = "Code %s: %s" % [result, ServerConnection.error_message] if result != OK else "Send data: %s" %data


func _on_ConnectButton_pressed() -> void:
	connect_result.text = "establishing server connection..."
	var result:int = yield(ServerConnection.connect_to_server_async(), "completed")
	connect_result.text = "Code %s: %s" % [result, ServerConnection.error_message] if result != OK else "CONNECTED TO SERVER!"


func _on_data_recieved(data:String):
	recieved_data.text = data


func _on_ipv6_text_changed(new_text: String) -> void:
	ip_address = new_text


func _on_HostServerButton_pressed() -> void:
	start_server()


func _on_PeerToPeerButton_pressed() -> void:
	join_server()


remote func button_pressed(value:bool)-> void:
	recieved_data.text = "button pressed: " + str(value)
	print("remote function triggered")


func _on_TestPeerToPeerButton_toggled(button_pressed: bool) -> void:
	print("players:")
	print(players)
	print("connected ids:")

	rpc("button_pressed", button_pressed)


func start_server():
	player_name = 'Server'
	var host    = NetworkedMultiplayerENet.new()

	var err = host.create_server(DEFAULT_PORT, MAX_PEERS)

	if (err!=OK):
		print("ERROR CREATING SERVER ON PORT " + str(DEFAULT_PORT))
		return

	get_tree().set_network_peer(host)

	spawn_player(1)

func join_server():
	player_name = 'Client'
	var host = NetworkedMultiplayerENet.new()
	var err
	if ip_address:
		err = host.create_client(ip_address, DEFAULT_PORT)
	else:
		for ip in IP.get_local_addresses():
			err = host.create_client(ip, DEFAULT_PORT)
			if err == OK:
				ipv6_text_edit.text = ip
				ip_address = ip

	if err != OK:
		print("ERROR JOINING SERVER WITH IP " + str(ip_address))
	else:
		print("joined server")
	get_tree().set_network_peer(host)


func _player_connected(id):
	print("Player connected: " + str(id))

func _player_disconnected(id):
	unregister_player(id)
	rpc("unregister_player", id)

func _connected_ok():
	rpc_id(1, "user_ready", get_tree().get_network_unique_id(), player_name)

remote func user_ready(id, player_name):
	if get_tree().is_network_server():
		rpc_id(id, "register_in_game")

remote func register_in_game():
	rpc("register_new_player", get_tree().get_network_unique_id(), player_name)
	register_new_player(get_tree().get_network_unique_id(), player_name)

func _server_disconnected():
	quit_game()

remote func register_new_player(id, name):
	if get_tree().is_network_server():
		rpc_id(id, "register_new_player", 1, player_name)

		for peer_id in players:
			rpc_id(id, "register_new_player", peer_id, players[peer_id])

	players[id] = name
	spawn_player(id)

#remote func register_player(id, name):
#	if get_tree().is_network_server():
#		rpc_id(id, "register_player", 1, player_name)
#
#		for peer_id in players:
#			rpc_id(id, "register_player", peer_id, players[peer_id])
#			rpc_id(peer_id, "register_player", id, name)
#
#	players[id] = name

remote func unregister_player(id):
	get_node("/root/" + str(id)).queue_free()
	players.erase(id)

func quit_game():
	get_tree().set_network_peer(null)
	players.clear()

func spawn_player(id):
	print("player ID "+ str(id) + " spawned")
#	var player_scene = preload(PLAYER_CURSOR)
#	var player       = player_scene.instance()
#
#	player.set_name(str(id))
#
#	if id == get_tree().get_network_unique_id():
#		player.set_network_master(id)
#
#		player.player_id = id
#		player.control   = true
#
#	get_parent().add_child(player)
