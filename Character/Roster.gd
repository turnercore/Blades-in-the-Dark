extends PopupScreen

export (NodePath) onready var character_container = get_node(character_container) as VBoxContainer
export (PackedScene) onready var character_setup_scene

var pcs_buttons:Dictionary = {}

func _ready() -> void:
	._ready()
	setup()
	GameData.pc_library.connect("resource_added", self, "_on_roster_added")
	GameData.pc_library.connect("resource_removed", self, "_on_roster_removed")


func setup()-> void:
	for child in character_container.get_children():
		child.queue_free()

	var pcs:Array = GameData.pc_library.get_catalogue()

	for pc in pcs:
		add_character(pc)


func add_character(pc:NetworkedResource)-> void:
	var button: = Button.new()
	button.text = pc.find("name")
	button.connect("pressed", self, "on_character_selected", [pc])
	character_container.add_child(button)
	pcs_buttons[pc] = button


func remove_character(pc:NetworkedResource)-> void:
	var button:Button = pcs_buttons[pc]
	pcs_buttons.erase(pc)
	button.queue_free()


func _on_character_selected(pc:NetworkedResource)-> void:
	GameData.active_pc = pc
	self.hide()


func _on_NewPlayerCharacterButton_pressed() -> void:
	#Create new character popupx
	var character_setup = character_setup_scene.instance()
	Events.popup(character_setup)
	hide()


func _on_roster_removed(pc:NetworkedResource) -> void:
	remove_character(pc)


func _on_roster_added(pc:NetworkedResource) -> void:
	add_character(pc)
