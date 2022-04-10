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

signal popup(popup)
func popup(popup)-> void:
	var new_popup
	if popup is PackedScene:
		new_popup = popup.instance()
	elif popup is Node:
		new_popup = popup
	emit_signal("popup", new_popup)

#Not passing the actual popup that emits this, because there should be only one,
#This may need to change in MULTIPLAYER
signal popup_finished

signal map_scroll_speed_changed(scroll_speed)
signal info_broadcasted(info)

signal roster_updated

signal chat_selected
signal chat_deselected

signal clock_updated(id, clock_data)
func emit_clock_updated(id:String, clock_data:Dictionary)->void:
	emit_signal("clock_updated", id, clock_data)
