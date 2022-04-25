# List of notifications that appear when users join or leave the game.
extends Control

const Notification := preload("res://UI//Notification.tscn")

func _ready() -> void:
	ServerConnection.connect("server_disconnected", self, "_on_server_disconnected")
	ServerConnection.connect("user_joined", self, "_on_user_joined")
	ServerConnection.connect("user_left", self, "_on_user_left")

func add_notification(username: String, color: Color, disconnected := false) -> void:
	if not Notification:
		return
	var notification := Notification.instance()
	add_child(notification)
	notification.setup(username, color, disconnected)

func _on_user_joined(username:String)-> void:
	add_notification(username, Color.green, false)

func _on_user_left(username:String)-> void:
	add_notification(username, Color.red, true)

func _on_server_disconnected()-> void:
	add_notification("YOU", Color.red, true)
