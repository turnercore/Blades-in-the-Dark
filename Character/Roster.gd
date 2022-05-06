extends PopupScreen

export (PackedScene) var character_scene
export (NodePath) onready var character_container = get_node(character_container) as VBoxContainer
export (PackedScene) onready var character_setup_scene

func _ready() -> void:
	GameSaver.connect("roster_loaded", self, "_on_roster_loaded")
	Events.connect("roster_updated", self, "_on_roster_updated")
	GameData.connect("roster_updated", self, "_on_roster_updated")
	if not GameData.roster.empty():
		setup(GameData.roster)


func setup(playbooks:Array)-> void:
	for child in character_container.get_children():
		child.queue_free()
	for playbook in playbooks:
		var new_character_scene = character_scene.instance()
		new_character_scene.playbook = playbook
		character_container.add_child(new_character_scene)
		new_character_scene.connect("pressed", self, "_on_character_selected")


func _on_roster_updated()->void:
	if not GameData.roster.empty():
		setup(GameData.roster)


func _on_roster_loaded(roster:Array)-> void:
	setup(roster)


func _on_character_selected()-> void:
	self.hide()


func _on_NewPlayerCharacterButton_pressed() -> void:
	#Create new character popup
	var character_setup = character_setup_scene.instance()
	Events.popup(character_setup)



func _on_Roster_modal_closed() -> void:
	Events.emit_signal("popup_finished")
