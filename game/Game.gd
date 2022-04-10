extends Node

export (NodePath) onready var roster = get_node(roster) as Control
export (NodePath) onready var clock_screen = get_node(clock_screen) as Control

func _ready() -> void:
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
