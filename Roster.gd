extends Control

export (PackedScene) var character_scene
export (NodePath) onready var character_container = get_node(character_container) as VBoxContainer
export (PackedScene) onready var create_character_popup

func _ready() -> void:
	GameSaver.connect("save_loaded", self, "_on_save_loaded")
	setup()


func setup()-> void:
	if Events.is_connected("popup_finished", self, "setup"):
		Events.disconnect("popup_finished", self, "setup")
	for child in character_container.get_children():
		child.queue_free()
	for playbook in GameData.pc_playbooks.roster:
		print("adding character to roster")
		var new_character_scene = character_scene.instance()
		new_character_scene.playbook = playbook
		character_container.add_child(new_character_scene)


func _on_save_loaded()-> void:
	setup()


func _on_NewPlayerCharacterButton_pressed() -> void:
	#Create new character popup
	var new_popup = create_character_popup.instance()
	Events.emit_signal("popup", new_popup)
	Events.connect("popup_finished", self, "setup")
