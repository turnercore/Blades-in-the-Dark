extends Node

var active_character:PlayerPlaybook setget _set_active_character


func _ready() -> void:
	Events.connect("character_changed", self, "_on_character_change")
	if GameData.pc_playbooks and "roster" in GameData.pc_playbooks:
		$"ViewportContainer/Viewport/Screen Layer/MainScreen/Roster".setup(GameData.pc_playbooks.roster)
	if not GameData.clocks.empty():
		$'ViewportContainer/Viewport/Screen Layer/MainScreen/Progress Clocks'.add_loaded_clocks(GameData.clocks)

func _set_active_character(value: PlayerPlaybook)-> void:
	active_character = value
	Events.emit_character_changed(value)


func _on_character_change(character: PlayerPlaybook)-> void:
	active_character = character
