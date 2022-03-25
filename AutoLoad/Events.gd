extends Node

signal chat_hidden
signal chat_unhidden

signal chat_message_sent(message)

signal player_connected(player)

signal crew_loaded(playbook)
func emit_crew_loaded(playbook: CrewPlaybook)-> void:
	emit_signal("crew_loaded", playbook)

signal main_screen_changed(screen)
