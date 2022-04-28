extends Node

export (NodePath) onready var roster_list = get_node(roster_list) as Control
export (NodePath) onready var clock_screen = get_node(clock_screen) as Control

func _ready() -> void:
	if not GameData.roster.empty():
		roster_list.setup(GameData.roster)
	if GameData.clocks:
		 clock_screen.refresh_clocks()
	if GameData.map:
		yield(get_tree(), "idle_frame")
		GameData.emit_signal("map_loaded")
