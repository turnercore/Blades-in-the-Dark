extends ScrollContainer

var playbook = CrewPlaybook.new() setget _change_playbook
var crew_loaded: bool = false
export (PackedScene) var crew_setup_sceen
export (PackedScene) var load_sceen
const ID: String = "crew"

#Not sure if this is needed
enum tabs {
	CREW_SHEET,
	LAIR,
	SKILL_TREE,
	NOTES
}


func _ready() -> void:
	propagate_set_editable(self, false)
	connect_to_events()
	propogate_set_playbook_recursive(self)


func show_crew_setup()->void:
	var crew_setup_popup = crew_setup_sceen.instance()
	Events.emit_signal("popup", crew_setup_popup)


func propogate_set_playbook_recursive(node: Node)-> void:
	if "playbook" in node and node != self:
		node.set("playbook", playbook)
	for child in node.get_children():
		propogate_set_playbook_recursive(child)


func load_playbook(new_playbook: = CrewPlaybook.new(), override:bool = false)-> void:
	var save_crew_playbook = GameSaver.save_game.crew_playbook
	if override:
		self.playbook = new_playbook
	elif save_crew_playbook is CrewPlaybook:
		self.playbook = GameSaver.save_game.crew_playbook
	else:
		self.playbook = new_playbook

	if playbook.needs_setup:
		show_crew_setup()


func connect_to_events():
	GameSaver.connect("game_loaded", self, "_on_game_loaded")


func get_all_children_in_group_recursive(node: Node, group: String)->Array:
	var nodes: Array = []

	for child in node.get_children():
		if child.get_child_count() > 0:
			if child.is_in_group(group):
				nodes.append(child)
			nodes.append_array(get_all_children_in_group_recursive(child, group))
		else:
			if child.is_in_group(group):
				nodes.append(child)
	return nodes


func propagate_set_editable(parent: Node, editable: bool = false)->void:
	#set disabled to the opposite of the passed editable variable
	var disabled = not editable
	for child in parent.get_children():
		if child.is_in_group("skip_disable"):
			continue
		if child is Container:
			propagate_set_editable(child, editable)
		else:
			if "editable" in child:
				child.editable = editable
			if "disabled" in child:
				child.disabled = disabled
			if "readonly" in child:
				child.readonly = disabled
			if "flat" in child:
				child.flat = disabled


func _on_CheckButton_toggled(button_pressed: bool) -> void:
	propagate_set_editable(self, button_pressed)


func _on_LairPicture_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("left_click"):
		get_parent().current_tab = tabs.LAIR


func load_game(save_game: Resource)->void:
	if ID in save_game.playbooks:
		load_playbook(save_game.playbooks[ID], true)
	else:
		load_playbook()

func show_load_screen()-> void:
	var load_screen = load_sceen.instance()
	Events.emit_signal("popup", load_screen)


func _change_playbook(value: CrewPlaybook)->void:
	playbook = value
	propogate_set_playbook_recursive(self)


func _on_LoadButton_pressed() -> void:
	show_load_screen()


func _on_CreateButton_pressed() -> void:
	show_crew_setup()


func _on_game_loaded()-> void:
	self.playbook = GameSaver.save_game.crew_playbook
