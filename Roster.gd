extends Control

export (PackedScene) var character_scene
onready var character_container: = $PanelContainer/ScrollContainer/VBoxContainer

func _ready() -> void:
	GameSaver.connect("game_loaded", self, "_on_game_loaded")
	setup()


func setup()-> void:
	for child in character_container.get_children():
		child.queue_free()
	for playbook in GameSaver.save_game.pc_playbooks:
		print("adding character to roster")
		var new_character_scene = character_scene.instance()
		new_character_scene.playbook = playbook
		character_container.add_child(new_character_scene)


func _on_game_loaded()-> void:
	setup()
