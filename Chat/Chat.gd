extends WindowDialog

const id: int = 1

export (NodePath) onready var message_text = get_node_or_null(message_text) as LineEdit if message_text else null
export (NodePath) onready var chat = get_node_or_null(chat) as RichTextLabel if chat else null
export (NodePath) onready var users = get_node(users)
export (NodePath) onready var hide_button = get_node(hide_button) as Button
export (NodePath) onready var send_message_button = get_node(send_message_button) as Button
export (NodePath) onready var notification_number = get_node(notification_number) as Label
export (NodePath) onready var chat_notification_text = get_node(chat_notification_text) as Label
export (NodePath) onready var fullscreen_button = get_node(fullscreen_button) as Button
export (String) var hide_button_show_text:String = "Show Chat"

onready var chat_saver:ChatSaver = ChatSaver.new()

var chat_is_hidden: bool = false
var players: Array = []
var chat_notifications:int = 0
var _user: = ""
var saved_settings: = {
	"anchor_left": 0,
	"anchor_top": 0,
	"anchor_right": 0,
	"anchor_bottom": 0,
	"margin_left": 0,
	"margin_top": 0,
	"margin_right": 0,
	"margin_bottom": 0
}


func _ready() -> void:
	self.visible = true
	setup()
	connect_to_detection_recursive(self)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("open_chat"):
		popup_centered_clamped()


func connect_to_detection_recursive(node:Node)->void:
	if node.has_signal("focus_entered"):
		node.connect("focus_entered", self, "_on_Chat_focus_entered")
	if node.has_signal("focus_exited"):
		node.connect("focus_exited", self, "_on_Chat_focus_exited")
	if node.has_signal("mouse_entered"):
		node.connect("mouse_entered", self, "_on_Chat_mouse_entered")
	if node.has_signal("mouse_exited"):
		node.connect("mouse_exited", self, "_on_Chat_mouse_exited")

	for child in node.get_children():
		connect_to_detection_recursive(child)


func setup()->void:
	for player in players:
		users.add_item(player)
	allow_full_collapse()
	notification_number.hide()
	chat_notification_text.hide()
	chat.scroll_following = true
	Events.connect("chat_message_sent", self, "_on_chat_message_sent")
	Events.connect("player_connected", self, "_on_player_connected")
	chat_saver.init()


func allow_full_collapse()-> void:
	var children: = get_children()
	for child in children:
		if child is Control:
			child.rect_min_size.x = 0
			child.rect_min_size.y = 0


func _on_SendMessageButton_pressed() -> void:
	if not message_text or not message_text.text:
		return
	Events.emit_signal("chat_message_sent", message_text.text, _user)
	message_text.text = ""


func _on_chat_message_sent(message:String, user)->void:
	#Format the input and make sure it's safe
	message = message.strip_escapes().strip_edges()
	#Do nothing if imput is unuseable
	if message == "":
		return
	#Update chat text
	var new_message:String = "\n"+user+": " + message
	chat.text += new_message

	#Save message log

	chat_saver.chat_log.text += "\n"+user+": " + message
	chat_saver.save_chat(id)

	if user != _user and chat_is_hidden:
		chat_notifications += 1
		notification_number.text = str(chat_notifications)


func propagate_hide_or_show(node: Node, exception_nodes: Array = [], hide: bool = true) -> void:
	if not Node:
		return

	if hide:
		for child in node.get_children():
			if child is Container:
				propagate_hide_or_show(child, exception_nodes, true)
			elif child is Control and not exception_nodes.has(child):
				child.hide()

	elif not hide:
		for child in node.get_children():
			if child is Container:
				propagate_hide_or_show(child, exception_nodes, false)
			elif child is Control and not exception_nodes.has(child):
				child.show()


func _on_MessageText_text_entered(_new_text: String) -> void:
	send_message_button.emit_signal("pressed")


func _on_player_connected(player)->void:
	players.append(player)
	users.clear()
	for player in players:
		users.add_item(player)


func _on_LoadButton_pressed() -> void:
	chat_saver.load_chat(id)
	chat.text = chat_saver.chat_log.text



func save_settings() ->void:
	for setting in saved_settings.keys():
		saved_settings[setting] = get(setting)


func load_settings()-> void:
	for setting in saved_settings.keys():
		set(setting, saved_settings[setting])


func _on_Fullscreen_toggled(button_pressed: bool) -> void:
	if button_pressed:
		#Save current position settings, set to fullscreen
		save_settings()
		for setting in saved_settings.keys():
			set(setting, 0)
		anchor_bottom = 1
		anchor_right = 1
	else:
		#load saved position settings
		load_settings()


func _on_Hide_toggled(is_hidden: bool) -> void:
	if is_hidden:
		save_settings()
		propagate_hide_or_show(self, [hide_button], true)
		hide_button.text = hide_button_show_text
		chat_notification_text.show()
		notification_number.show()
		chat_is_hidden = true
		Events.emit_signal("chat_hidden")

		margin_left = 0
		margin_top = 0
		margin_right = 25
		margin_bottom = 0
		anchor_left = 0.35
		anchor_top = 0.95
		anchor_right = 0.5
		anchor_bottom = 1

	else:
		load_settings()
		propagate_hide_or_show(self, [hide_button, chat_notification_text, notification_number], false)
		hide_button.text = "Hide"
		chat_notification_text.hide()
		notification_number.hide()
		notification_number.text = "0"
		chat_is_hidden = false
		chat_notifications = 0
		Events.emit_signal("chat_unhidden")


func set_transparency(is_transparent:bool)->void:
	modulate.a = 0.4 if is_transparent else 1.0


func _on_Chat_mouse_entered() -> void:
	set_transparency(false)
	Events.emit_signal("chat_selected")


func _on_Chat_mouse_exited() -> void:
	set_transparency(true)
	Events.emit_signal("chat_deselected")


func _on_Chat_focus_entered() -> void:
	set_transparency(false)
	Events.emit_signal("chat_selected")


func _on_Chat_focus_exited() -> void:
	set_transparency(true)
	Events.emit_signal("chat_deselected")


func _on_HideButton_toggled(button_pressed: bool) -> void:
	pass # Replace with function body.


func _on_FullscreenButton_toggled(button_pressed: bool) -> void:
	pass # Replace with function body.
