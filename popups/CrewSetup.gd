extends Popup

onready var pages: Array = $SetupPages.get_children()
var active_page = 0
var current_page: Node
var new_playbook: = NetworkedResource.new()
var on_start_screen: = false
export(NodePath) onready var type_options = get_node(type_options)


func _ready() -> void:
	for page in pages:
		page.visible = false

	current_page = pages.front()
	current_page.visible = true
	Globals.propagate_set_property_recursive(self, "resource", new_playbook)

	for type in GameData.srd.crew_types:
		var item:String = str(type)
		item = item.capitalize()
		type_options.add_item(item)


func _on_NextButton_pressed() -> void:
	var pages_hidden: = false
	for page in pages:
		if not pages_hidden and page.visible:
			page.visible = false
			pages_hidden = true
		elif pages_hidden:
			page.visible = true
			break


func setup_resource(type: String)-> void:
	type = type.to_lower()
	var crew: = CrewConstructor.new()
	var crew_data: = crew.build(type, GameData.srd)
	new_playbook.setup(crew_data)


func _on_type_options_item_selected(index: int) -> void:
	var crew_type:String = type_options.get_item_text(index)
	setup_resource(crew_type)
	$SetupPages/CrewChoices/NextButton.disabled = false


func _on_next() -> void:
	current_page.visible = false
	active_page += 1
	current_page = pages[active_page]
	current_page.visible = true


func _on_FinishedButton_pressed() -> void:
	GameData.crew_playbook_resource = new_playbook
	Events.emit_signal("popup_finished")
	if on_start_screen:
		get_tree().change_scene_to(Globals.GAME_SCENE)
#		get_tree().change_scene(Globals.GAME_SCENE_PATH)
	else: queue_free()
