extends PopupScreen

# Maximum number of times to retry a server request if the previous attempt failed.
const MAX_REQUEST_ATTEMPTS := 3


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

var _server_request_attempts := 0


func _ready() -> void:
	ServerConnection.connect("data_recieved", self, "_on_data_recieved")


# Requests the server to authenticate the player using their credentials.
# Attempts authentication up to `MAX_REQUEST_ATTEMPTS` times.
func authenticate_user_async(email: String, password: String) -> int:
	var result := -1
	while result != OK:
		if _server_request_attempts == MAX_REQUEST_ATTEMPTS:
			break
		_server_request_attempts += 1
		result = yield(ServerConnection.login_async(email, password), "completed")

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
