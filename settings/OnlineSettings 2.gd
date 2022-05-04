extends PopupScreen

onready var server_label: = $PanelContainer/MarginContainer/VBoxContainer/Label
onready var match_id_label: = $PanelContainer/MarginContainer/VBoxContainer/match_id
onready var users_label: = $PanelContainer/MarginContainer/VBoxContainer/users
var online:bool = false

func _ready() -> void:
	server_label.text = "Offline" if not ServerConnection.is_connected_to_server else "Match ID:"
	match_id_label.visible = ServerConnection.is_connected_to_server
	online = true if ServerConnection.is_connected_to_server else false
	ServerConnection.connect("server_disconnected", self, "_on_server_disconnected")
	ServerConnection.connect("server_connected", self, "_on_server_connected")
	ServerConnection.connect("presences_changed", self, "_on_presences_changed")
	if not ServerConnection.presences.empty():
		users_label.text = ""
		for presence in ServerConnection.presences:
			users_label.text += presence + "\n"


func popup()-> void:
	.popup()
	if ServerConnection.is_connected_to_server:
		server_label.text = "Match ID: "
		match_id_label.text = str(ServerConnection._match.match_id)
		match_id_label.visible = true
	else:
		server_label.text = "Offline"
		match_id_label.visible = false

	online = true if ServerConnection.is_connected_to_server else false


func _on_DisconnectButton_pressed() -> void:
	var result = yield(ServerConnection.disconnect_from_server_async(), "completed")
	if result != OK:
		print("ERROR DISCONNECTING FROM SERVER")


func _on_server_connected()-> void:
	online = true
	server_label.text = "Match ID: "
	match_id_label.text = str(ServerConnection._match.match_id)
	match_id_label.visible = true


func _on_server_disconnected()-> void:
	server_label.text = "Offline"
	match_id_label.visible = false
	online = false


func _on_presences_changed(presences)-> void:
	users_label.text = ""
	if not presences.empty():
		for presence in presences:
			users_label.text += presence + "\n"
