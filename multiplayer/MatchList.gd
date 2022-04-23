extends PopupScreen

export (NodePath) onready var match_list = get_node(match_list) as VBoxContainer
export (NodePath) onready var result_label = get_node(result_label) as Label
export (PackedScene) var match_button

func _ready() -> void:
	if not ServerConnection.is_connected_to_server:
		print("NOT CONNECTED TO SERVER")
		result_label.text = "NOT CONNECTED TO SERVER"
		return
	var result:NakamaAPI.ApiMatchList = yield(ServerConnection.list_matches_async(), "completed")
	for server_match in result.matches:
		var new_match: Button = match_button.instance()
		new_match.text = server_match.match_id
		new_match.connect("pressed", self, "_on_match_pressed", [server_match.match_id])
		match_list.add_child(new_match)


func _on_match_pressed(match_id:String) -> void:
	match_id = match_id.strip_edges()
	var result:int = yield(ServerConnection.join_match_async(match_id), "completed")
	if result == OK:
		result_label.text = "CONNECTED TO MATCH"
	else:
		result_label.text = "Error code %s: %s" % [result, ServerConnection.error_message]
