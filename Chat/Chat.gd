extends MarginContainer

const id: int = 1
export (NodePath) onready var main_screen = get_node_or_null(main_screen) as HSplitContainer if main_screen else null
export (NodePath) onready var message_text = get_node_or_null(message_text) as LineEdit if message_text else null
export (NodePath) onready var chat = get_node_or_null(chat) as RichTextLabel if chat else null
onready var chat_vsplit: = $MarginContainer/HBoxContainer/ChatBox
onready var users: = $MarginContainer/HBoxContainer/VBoxContainer/Users
onready var hide_button: = $MarginContainer/HBoxContainer/ChatBox/ChatButtons/Hide
onready var send_message_button: = $MarginContainer/HBoxContainer/ChatBox/ChatButtons/SendMessageButton
onready var notification_number: = $MarginContainer/HBoxContainer/ChatBox/ChatButtons/NotificationNumber
onready var chat_notification_text: = $MarginContainer/HBoxContainer/ChatBox/ChatButtons/ChatNotifications
onready var fullscreen_button: = $MarginContainer/HBoxContainer/ChatBox/ChatButtons/FullscreenButton
onready var chat_saver:ChatSaver = ChatSaver.new()
export (String) var hide_button_show_text:String = "Show Chat"
var chat_is_hidden: bool = false
var players: Array = []
var chat_notifications:int = 0
var _user: = "Turner"


func _ready() -> void:
	setup()

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


func _on_Hide_pressed() -> void:
	if chat_is_hidden:
		propogate_hide_or_show(self, [hide_button, chat_notification_text, notification_number], false)
		hide_button.text = "Hide"
		chat_notification_text.hide()
		notification_number.hide()
		notification_number.text = "0"
		chat_is_hidden = false
		chat_notifications = 0
		Events.emit_signal("chat_unhidden")
	else:
		propogate_hide_or_show(self, [hide_button], true)
		hide_button.text = hide_button_show_text
		chat_notification_text.show()
		notification_number.show()
		chat_is_hidden = true
		Events.emit_signal("chat_hidden")


func propogate_hide_or_show(node: Node, exception_nodes: Array = [], hide: bool = true) -> void:
	if not Node:
		return

	if hide:
		for child in node.get_children():
			if child is Container:
				propogate_hide_or_show(child, exception_nodes, true)
			elif child is Control and not exception_nodes.has(child):
				child.hide()

	elif not hide:
		for child in node.get_children():
			if child is Container:
				propogate_hide_or_show(child, exception_nodes, false)
			elif child is Control and not exception_nodes.has(child):
				child.show()


func _on_MessageText_text_entered(new_text: String) -> void:
	send_message_button.emit_signal("pressed")

func _on_player_connected(player)->void:
	players.append(player)
	users.clear()
	for player in players:
		users.add_item(player)


func _on_LoadButton_pressed() -> void:
	chat_saver.load_chat(id)
	chat.text = chat_saver.chat_log.text


func _on_Fullscreen_toggled(button_pressed: bool) -> void:
	main_screen.visible = not button_pressed
	if button_pressed:
		fullscreen_button.text = "Minimize"
	else:
		fullscreen_button.text = "Fullscreen"
	print("Fullscreen but plres")
