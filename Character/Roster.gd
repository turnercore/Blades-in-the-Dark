extends PopupScreen

export (PackedScene) var character_scene
export (NodePath) onready var character_container = get_node(character_container) as VBoxContainer
export (PackedScene) onready var create_character_popup

func _ready() -> void:
	GameSaver.connect("pc_playbooks_loaded", self, "_on_pc_playbooks_loaded")
	Events.connect("roster_updated", self, "_on_roster_updated")
	if GameData.pc_playbooks and "roster" in GameData.pc_playbooks:
		setup(GameData.pc_playbooks.roster)


func setup(playbooks:Array)-> void:
	for child in character_container.get_children():
		child.queue_free()
	for playbook in playbooks:
		var new_character_scene = character_scene.instance()
		new_character_scene.playbook = playbook
		character_container.add_child(new_character_scene)
		new_character_scene.connect("pressed", self, "_on_character_selected")


func _on_roster_updated()->void:
	if GameData.pc_playbooks and "roster" in GameData.pc_playbooks:
		setup(GameData.pc_playbooks.roster)


func _on_pc_playbooks_loaded(pc_playbooks:Array)-> void:
	setup(pc_playbooks)


func _on_character_selected()-> void:
	self.hide()


func _on_NewPlayerCharacterButton_pressed() -> void:
	#Create new character popup
	var new_popup = create_character_popup.instance()
	Events.popup(new_popup)



func _on_Roster_modal_closed() -> void:
	Events.emit_signal("popup_finished")
