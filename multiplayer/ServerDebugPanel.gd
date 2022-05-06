extends PanelContainer

onready var server_match_info: = $VBoxContainer/match
onready var match_presences: = $VBoxContainer/presences


func _process(delta: float) -> void:
	server_match_info.text = str(ServerConnection._match)
	match_presences.text = str(ServerConnection.presences)
