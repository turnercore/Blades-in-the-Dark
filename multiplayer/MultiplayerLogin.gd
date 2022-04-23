extends PopupScreen

export (NodePath) onready var email_line_edit = get_node(email_line_edit) as LineEdit
export (NodePath) onready var password_line_edit = get_node(password_line_edit) as LineEdit
export (NodePath) onready var login_button = get_node(login_button) as Button
export (NodePath) onready var register_button = get_node(register_button) as Button
export (NodePath) onready var display_name_line_edit = get_node(display_name_line_edit) as LineEdit
export (NodePath) onready var result_label = get_node(result_label) as Label

var is_valid_email: = false
var is_valid_password: = false
var _server_request_attempts: = 0
var display_name: = ""


func authenticate_user_async(email: String, password: String) -> int:
	var result := -1
	while result != OK:
		if _server_request_attempts == ServerConnection.MAX_REQUEST_ATTEMPTS:
			break
		_server_request_attempts += 1
		result = yield(ServerConnection.login_async(email, password), "completed")

	_server_request_attempts = 0
	return result


func _on_LoginButton_pressed() -> void:
	var email:String = email_line_edit.text.c_escape().strip_edges()
	var password:String = password_line_edit.text.strip_edges()
	result_label.text = "logging in..."
	var result:int = yield(authenticate_user_async(email, password), "completed")

	if result == OK:
		result_label.text =  "LOGGED IN"
		connect_to_server()
	else:
		result_label.text = "Error code %s: %s" % [result, ServerConnection.error_message]




func connect_to_server()-> void:
	result_label.text = "connecting to server..."
	var result:int = yield(ServerConnection.connect_to_server_async(), "completed")
	if result == OK:
		result_label.text =  "CONNECTED"
	else:
		result_label.text = "Error code %s: %s" % [result, ServerConnection.error_message]

	if display_name:
		result = yield(ServerConnection.update_display_name_async(display_name), "completed")

	if result == OK:
		PlayerData.display_name = display_name
		result_label.text = "CONNECTED"
		hide()
	else:
		result_label.text = "Error code %s: %s" % [result, ServerConnection.error_message]


func _on_RegisterButton_pressed() -> void:
	result_label.text = "registering new account... \n (please remember your credentials)"
	var email:String = email_line_edit.text.c_escape().strip_edges()
	var password:String = password_line_edit.text.strip_edges()
	var result:int = yield(ServerConnection.register_async(email, password), "completed")
	if result == OK:
		result_label.text =  "REGISTERED"
		_on_LoginButton_pressed()
	else:
		result_label.text = "Error code %s: %s" % [result, ServerConnection.error_message]


func _on_password_text_changed(new_text: String) -> void:
	if new_text.c_escape().strip_edges().length() > 8:
		is_valid_password = true
		if is_valid_email:
			login_button.disabled = false
			register_button.disabled = false
	else:
		is_valid_password = false
		login_button.disabled = true
		register_button.disabled = true


func _on_email_text_changed(new_text: String) -> void:
	if "@" in new_text and "." in new_text:
		is_valid_email = true
		if is_valid_password:
			login_button.disabled = false
			register_button.disabled = false
	else:
		is_valid_email = false
		login_button.disabled = true
		register_button.disabled = true


func _on_display_name_text_changed(new_text: String) -> void:
	display_name = new_text.c_escape().strip_escapes().strip_edges()
