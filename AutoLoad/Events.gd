extends Node

signal chat_hidden
signal chat_unhidden

signal chat_message_sent(message)

signal player_connected(player)

signal crew_loaded(playbook)
func emit_crew_loaded(playbook: CrewPlaybook)-> void:
	emit_signal("crew_loaded", playbook)

signal character_changed(playbook)
func emit_character_changed(playbook: Playbook)-> void:
	emit_signal("character_changed", playbook)

signal main_screen_changed(screen)

signal popup(popup_scene)
signal popup_finished

signal map_scroll_speed_changed(scroll_speed)
signal info_broadcasted(info)

signal chat_selected
signal chat_deselected
