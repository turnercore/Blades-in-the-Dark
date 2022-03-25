extends ScrollContainer

export (Resource) onready var crew_playbook = crew_playbook as CrewPlaybook setget _change_crew_playbook
var crew_loaded: bool = false
const ID: String = "crew"

#Not sure if this is needed
enum tabs {
	CREW_SHEET,
	LAIR,
	SKILL_TREE,
	NOTES
}


signal loaded(crew_playbook)
signal saved(crew_playbook)

func _ready() -> void:
	propagate_set_editable(self, false)
	if not crew_loaded: show_crew_setup()
#	load_playbook()
	connect_to_events()


func show_crew_setup()->void:
	pass


func load_playbook(playbook: = CrewPlaybook.new(), override:bool = false)-> void:
	var game_saver_crew_playbook = GameSaver.save_game.playbooks[ID] if ID in GameSaver.save_game.playbooks else null
	if override:
		crew_playbook = playbook
	elif game_saver_crew_playbook is CrewPlaybook:
		crew_playbook = GameSaver.save_game.playbooks[ID]
	else:
		crew_playbook = playbook

	if crew_playbook.needs_setup:
		crew_playbook.setup(GameSaver.srd_json, "shadows")
		crew_playbook.needs_setup = false

	emit_signal("loaded", crew_playbook)


func connect_to_events():
	Events.connect("crew_loaded", self, "_on_crew_loaded")

	var children_with_data: Array = get_all_children_in_group_recursive(self, "data")
	for node in children_with_data:
		node.connect("property_updated", self, "_on_child_property_updated")
		connect("loaded", node, "_on_load")


func _on_child_property_updated(playbook_field: String, property_value)->void:
	if crew_playbook.save_path(playbook_field, property_value):
		GameSaver.data_changed = true
	else:
		print("error saving " + playbook_field)



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


func save(save_game: Resource)->void:
	if not ID in save_game.playbooks: save_game.playbooks[ID] = {}
	save_game.playbooks[ID] = crew_playbook
	emit_signal("saved", crew_playbook)


func load_game(save_game: Resource)->void:
	if ID in save_game.playbooks:
		load_playbook(save_game.playbooks[ID], true)
	else:
		load_playbook()


func _change_crew_playbook(value: CrewPlaybook)->void:
	crew_playbook = value


func _on_LoadButton_pressed() -> void:
	GameSaver.load_all()
	emit_signal("loaded", crew_playbook)


func _on_SaveButton_pressed() -> void:
	GameSaver.save_node(self)
