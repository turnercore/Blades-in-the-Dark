extends Control

export (PackedScene) var character_scene
export (NodePath) onready var character_container = get_node(character_container) as VBoxContainer
export (PackedScene) onready var create_character_popup

func _ready() -> void:
	GameSaver.connect("pc_playbooks_loaded", self, "_on_pc_playbooks_loaded")
	if GameData.pc_playbooks and "roster" in GameData.pc_playbooks:
		setup(GameData.pc_playbooks.roster)


func setup(playbooks:Array)-> void:
	if Events.is_connected("popup_finished", self, "setup"):
		Events.disconnect("popup_finished", self, "setup")
	for child in character_container.get_children():
		child.queue_free()
	for playbook in playbooks:
		var new_character_scene = character_scene.instance()
		new_character_scene.playbook = playbook
		character_container.add_child(new_character_scene)


func _on_pc_playbooks_loaded(pc_playbooks:Array)-> void:
	setup(pc_playbooks)


func _on_NewPlayerCharacterButton_pressed() -> void:
	#Create new character popup
	var new_popup = create_character_popup.instance()
	Events.emit_signal("popup", new_popup)
	Events.connect("popup_finished", self, "setup")
