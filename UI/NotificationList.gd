# List of notifications that appear when users join or leave the game.
extends Control

const Notification := preload("res://UI//Notification.tscn")

func _ready() -> void:
	ServerConnection.connect("server_disconnected", self, "_on_server_disconnected")
	ServerConnection.connect("user_joined", self, "_on_user_joined")
	ServerConnection.connect("user_left", self, "_on_user_left")
	Events.connect("notification", self, "_on_notification")

func add_notification(text: String, color: Color = Color.white) -> void:
	var message:String = generate_message(text, color)
	if not Notification:
		return
	var notification := Notification.instance()
	add_child(notification)
	notification.setup(message)


func generate_message(text:String, color:Color)-> String:
	var message: = "[color=#%s]%s[/color]" % [color.to_html(false), text]
	return message


func _on_user_joined(username:String)-> void:
	add_notification(username, Color.green)

func _on_user_left(username:String)-> void:
	add_notification(username, Color.red)

func _on_server_disconnected()-> void:
	add_notification("YOU", Color.red)

func _on_notification(text:String, color: = Color.white)-> void:
	add_notification(text, color)
