extends Node

export (NodePath) onready var roster = get_node(roster) as Control
export (NodePath) onready var clock_screen = get_node(clock_screen) as Control

func _ready() -> void:
#	ServerConnection.connect("match_state_recieved", self, "_on_match_state_recieved")
#	ServerConnection.connect("server_connected", self, "_on_server_connected")

	if GameData.pc_playbooks and "roster" in GameData.pc_playbooks:
		roster.setup(GameData.pc_playbooks.roster)
	if GameData.clocks:
		 clock_screen.add_loaded_clocks(GameData.clocks)
	if GameData.map:
		yield(get_tree(), "idle_frame")
		GameData.emit_signal("map_loaded", GameData.map)


func _on_MainScreenButtons_mouse_entered() -> void:
	#This is where I need to disable the map interactions and other shit
	pass

#func _on_match_state_recieved(match_state: NakamaRTAPI.MatchData)-> void:
#	var op_code: = match_state.op_code
#	var data: = match_state.data
#	print("Match state recieved.")
#	print("Op_Code: %s" % op_code)
#	print("Data: %s" % data)


func _on_server_connected()-> void:
	pass
