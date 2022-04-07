extends Node

var active_character:PlayerPlaybook setget _set_active_character

func _ready() -> void:
	Events.connect("character_changed", self, "_on_character_change")

func _set_active_character(value: PlayerPlaybook)-> void:
	active_character = value
	Events.emit_character_changed(value)


func _on_character_change(character: PlayerPlaybook)-> void:
	active_character = character
