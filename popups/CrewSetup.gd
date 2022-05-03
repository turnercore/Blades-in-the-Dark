extends PopupScreen

const DEFAULT_MAP: = {
	"name": "Doskvol"
}

onready var pages: Array = $MarginContainer/PanelContainer/SetupPages.get_children()
var active_page = 0
var current_page: Node
var crew_playbook: = NetworkedResource.new()
var on_start_screen: = false
export(NodePath) onready var type_options = get_node(type_options)
var coins: = 2 setget _set_coins
onready var coin_container: = $MarginContainer/Coins


export (NodePath) onready var lair_location_options = get_node(lair_location_options) as OptionButton
export (NodePath) onready var lair_location_description = get_node(lair_location_description) as Label
export (NodePath) onready var region_wealth = get_node(region_wealth) as Label
export (NodePath) onready var region_security = get_node(region_security) as Label
export (NodePath) onready var region_criminal = get_node(region_criminal) as Label
export (NodePath) onready var region_occult = get_node(region_occult) as Label
onready var region_intro: = get_node("MarginContainer/PanelContainer/SetupPages/CrewChoices-1/Intro")


var region_choices: = []
var selected_region

func _ready() -> void:
	self.coins = 2
	for page in pages:
		page.visible = false

	current_page = pages.front()
	current_page.visible = true

	for type in GameData.srd.crew_types:
		var item:String = str(type)
		item = item.capitalize()
		type_options.add_item(item)

	setup_choices(GameData.srd)


func setup_choices(srd:Dictionary)-> void:
	var all_regions = srd.map_regions

	for region in all_regions:
		if region.map == DEFAULT_MAP.name:
			region_choices.append(region)

	for region in region_choices:
		lair_location_options.add_item(region.name)



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
	crew_playbook.setup(crew_data)
	Globals.propagate_set_property_recursive(self, "resource", crew_playbook)


func _on_type_options_item_selected(index: int) -> void:
	var crew_type:String = type_options.get_item_text(index)
	setup_resource(crew_type)
	$MarginContainer/PanelContainer/SetupPages/CrewChoices/crew_type_description.text = GameData.srd.crew_types[crew_playbook.find("type")].description
	$MarginContainer/PanelContainer/SetupPages/CrewChoices/NextButton.disabled = false


func _on_next() -> void:
	current_page.visible = false
	active_page += 1
	current_page = pages[active_page]
	current_page.visible = true


func _on_FinishedButton_pressed() -> void:
	GameData.crew_playbook_resource = crew_playbook
	Events.emit_signal("popup_finished")
	if on_start_screen:
		get_tree().change_scene_to(Globals.GAME_SCENE)
#		get_tree().change_scene(Globals.GAME_SCENE_PATH)
	else: queue_free()

func _set_coins(value:int)-> void:
	coins = value
	var coins_set: = 0

	for coin_scene in coin_container.get_children():
		if not coin_scene is Coin: continue
		if coins_set >= coins:
			coin_scene.pressed = false
		else:
			coin_scene.pressed = true
			coins_set += 1


func _on_lair_location_item_selected(index: int) -> void:
	var region_name:String = lair_location_options.get_item_text(index)
	for region in region_choices:
		if region.name == region_name:
			selected_region = region
			break
	lair_location_description.text = selected_region.description
	region_wealth.text = str(selected_region.wealth)
	region_occult.text = str(selected_region.occult_influence)
	region_security.text = str(selected_region.security_and_safety)
	region_criminal.text = str(selected_region.criminal_influence)
	region_intro.visible = false
