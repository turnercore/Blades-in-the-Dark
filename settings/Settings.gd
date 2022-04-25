extends PopupScreen

onready var server_label: = $Settings/MenuButtons/Label
onready var match_id_label: = $Settings/MenuButtons/match_id

func _ready() -> void:
	server_label.text = "Offline" if not ServerConnection.is_connected_to_server else "Match ID:"
	match_id_label.visible = ServerConnection.is_connected_to_server


func popup()-> void:
	.popup()
	if ServerConnection.is_connected_to_server:
		server_label.text = "Match ID: "
		match_id_label.text = str(ServerConnection._match.match_id)
		match_id_label.visible = true
	else:
		server_label.text = "Offline"
		match_id_label.visible = false
