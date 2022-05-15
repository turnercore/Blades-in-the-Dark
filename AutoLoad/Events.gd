extends Node

signal chat_hidden
signal chat_unhidden

signal connected_to_server

signal chat_message_sent(message)

signal player_connected(player)

signal crew_loaded(resource)
func emit_crew_loaded(playbook: NetworkedResource)-> void:
	emit_signal("crew_loaded", playbook)

signal character_selected(resource)
func emit_character_selected(playbook: NetworkedResource)-> void:
	emit_signal("character_selected", playbook)

signal mouse_locked(node)
signal mouse_unlocked(node)

signal open_screen(screen)

signal popup_finished
signal all_popups_finished
signal popup(popup, use_overlay)
func popup(popup, use_overlay:=true)-> void:
	if popup is String:
		emit_signal("popup", popup, use_overlay)
		return
	var new_popup:PopupScreen
	if popup is PackedScene:
		new_popup = popup.instance()
	elif popup is PopupScreen:
		new_popup = popup
	emit_signal("popup", new_popup, use_overlay)


signal map_scroll_speed_changed(scroll_speed)

signal tooltip_frozen(tooltip)
signal tooltip_container_transfered(tooltip_container)
signal notification(text, color)
func emit_notification(message:String, color: = Color.white)-> void:
	emit_signal("notification", message, color)

signal popup_layer_ready
signal info_broadcasted(info)
func emit_tooltip(tooltip)-> void:
	emit_signal("info_broadcasted", tooltip)

signal roster_updated

signal chat_selected
signal chat_deselected

signal clock_created(clock)
func emit_clock_created(clock:Clock)-> void:
	emit_signal("clock_created", clock)
signal clock_updated(clock)
func emit_clock_updated(clock:Clock)-> void:
	emit_signal("clock_updated", clock)
signal clock_removed(clock_id)
func emit_clock_removed(clock_id:String)-> void:
	emit_signal("clock_removed", clock_id)

signal map_changed(id)
func emit_map_changed(id:String)->void:
	emit_signal("map_changed", id)

signal map_note_clicked(note)
signal location_updated(note)
signal location_removed(pos)
signal location_created(note)

signal cursor_hovered
signal cursor_free

signal move_camera(pos)
func move_camera(pos: Vector2)->void:
	emit_signal("move_camera", pos)

signal pin_dropped(pin)
signal area_highlighted(area2D)
