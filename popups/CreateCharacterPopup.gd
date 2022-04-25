extends PopupPanel

export (NodePath) onready var type_options = get_node(type_options) as OptionButton
var pages: Array
var new_pc_playbook: = PlayerPlaybook.new()

func _ready() -> void:
	for child in $MarginContainer.get_children():
		pages.append(child)
		if pages.size() == 1:
			child.visible = true
		else:
			child.visible = false

	for type in GameData.srd.pc_types:
		var item:String = str(type)
		item = item.capitalize()
		type_options.add_item(item)

	Globals.propagate_set_playbook_recursive(self, new_pc_playbook, self)


func _on_NextButton_pressed() -> void:
	var pages_hidden: = false
	for page in pages:
		if not pages_hidden and page.visible:
			page.visible = false
			pages_hidden = true
		elif pages_hidden:
			page.visible = true
			break


func setup_playbook(type: String)-> void:
	type = type.to_lower()
	new_pc_playbook.setup(GameData.srd, type, true)


func _on_type_options_item_selected(index: int) -> void:
	$MarginContainer/Page1/VBox/CreateNewPlaybook.disabled = false


func _on_FinishButton_pressed() -> void:
	GameData.add_pc_to_roster(new_pc_playbook, true)
	GameData.save_all()
	Events.emit_signal("popup_finished")
	Events.emit_signal("roster_updated")
	queue_free()


func _on_CreateNewPlaybook_pressed() -> void:
	var pc_type:String = type_options.get_item_text(type_options.selected)
	setup_playbook(pc_type)
	var pages_hidden: = false
	for page in pages:
		if not pages_hidden and page.visible:
			page.visible = false
			pages_hidden = true
		elif pages_hidden:
			page.visible = true
			break
