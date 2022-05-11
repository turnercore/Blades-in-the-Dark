extends PopupScreen

const DEFAULT_MAP: = {
	"name": "Doskvol"
}

onready var pages: Array = $MarginContainer/PanelContainer/SetupPages.get_children()
var active_page = 0
var crew_playbook: = NetworkedResource.new()
var on_start_screen: = false
export(NodePath) onready var type_options = get_node(type_options)
var coins: = 2 setget _set_coins
onready var coin_container: = $MarginContainer/Coins

export (NodePath) onready var current_page_number_label = get_node(current_page_number_label) as Label
export (NodePath) onready var total_page_number_label = get_node(total_page_number_label) as Label
export (NodePath) onready var lair_location_options = get_node(lair_location_options) as OptionButton
export (NodePath) onready var lair_location_description = get_node(lair_location_description) as Label
export (NodePath) onready var region_wealth = get_node(region_wealth) as Label
export (NodePath) onready var region_security = get_node(region_security) as Label
export (NodePath) onready var region_criminal = get_node(region_criminal) as Label
export (NodePath) onready var region_occult = get_node(region_occult) as Label
export (NodePath) onready var region_intro = get_node(region_intro) as Label
export (NodePath) onready var operation_type_options = get_node(operation_type_options) as OptionButton
export (NodePath) onready var hunting_ground_location_options = get_node(hunting_ground_location_options) as OptionButton
export (NodePath) onready var hunting_grounds_description = get_node(hunting_grounds_description) as Label
export (NodePath) onready var faction_name_label = get_node(faction_name_label) as Label
export (NodePath) onready var faction_description_label = get_node(faction_description_label) as Label
export (NodePath) onready var starting_ability_options = get_node(starting_ability_options) as OptionButton
export (NodePath) onready var ability_description_label = get_node(ability_description_label) as Label
export (NodePath) onready var upgrade1_label = get_node(upgrade1_label) as Label
export (NodePath) onready var upgrade2_label = get_node(upgrade2_label) as Label
export (NodePath) onready var upgrade3_options = get_node(upgrade3_options) as OptionButton
export (NodePath) onready var upgrade4_options = get_node(upgrade4_options) as OptionButton
export (NodePath) onready var friendly_faction_options = get_node(friendly_faction_options) as OptionButton
export (NodePath) onready var friendly_faction_description_label = get_node(friendly_faction_description_label) as Label
export (NodePath) onready var angry_faction_description_label = get_node(angry_faction_description_label) as Label
export (NodePath) onready var angry_faction_options = get_node(angry_faction_options) as OptionButton
export (NodePath) onready var friendly_faction_interaction_options = get_node(friendly_faction_interaction_options) as OptionButton
export (NodePath) onready var angry_faction_interaction_options = get_node(angry_faction_interaction_options) as OptionButton
export (NodePath) onready var upgrade_description_label = get_node(upgrade_description_label) as Label
export (NodePath) onready var favorite_contact_options = get_node(favorite_contact_options) as OptionButton
export (NodePath) onready var favorite_contact_label = get_node(favorite_contact_label) as Label
export (NodePath) onready var friendly_contact_faction_options = get_node(friendly_contact_faction_options) as OptionButton
export (NodePath) onready var friendly_contact_faction_description = get_node(friendly_contact_faction_description) as Label
export (NodePath) onready var angry_contact_faction_options = get_node(angry_contact_faction_options) as OptionButton
export (NodePath) onready var angry_contact_faction_description = get_node(angry_contact_faction_description) as Label

var page_number:int =0

var region_choices: = []
var selected_region
var hunting_grounds: = {}
var hunting_ground_choices: = {}
var chosen_hunting_ground
var starting_faction
var selected_ability
var ability_choices: = {}
var upgrade_options: = {}
var upgrade1
var upgrade2
var upgrade3
var upgrade4
var faction_choices: = {}
var selected_friendly_faction
var friendly_interaction
var selected_angry_faction
var angry_interaction
var contact_choices: = {}
var selected_contact
var selected_contact_friendly_faction
var selected_contact_angry_faction
var has_influential_contact: = false

func _ready() -> void:
	self.coins = 2
	coin_container.visible = false
	for page in pages:
		page.visible = false
	pages[0].visible = true
	total_page_number_label.text = str(pages.size())

	for type in GameData.srd.crew_types:
		var item:String = str(type)
		item = item.capitalize()
		type_options.add_item(item)



func setup_choices(srd:Dictionary)-> void:
	var type:String = crew_playbook.find("type")
	#Set the starting region
	var all_regions = srd.map_regions

	for region in all_regions:
		if region.map == DEFAULT_MAP.name:
			region_choices.append(region)

	for region in region_choices:
		lair_location_options.add_item(region.name)

	#Set the hunting grounds and deal with the intial faction
	var starting_hunting_grounds: = []
	for id in srd.hunting_grounds:
		id = id as String
		if id.begins_with("starting_"):
			starting_hunting_grounds.append(srd.hunting_grounds[id])

	var i: = 100
	for ground in starting_hunting_grounds:
		hunting_ground_location_options.add_item("%s : %s" %[ground.region.capitalize(), ground.name.capitalize()], i)
		hunting_ground_choices[i] = ground
		i += 1

	for operation_type in srd.crew_types[type.to_lower()].operation_types:
		operation_type_options.add_item(operation_type)

	#Set abilities
	i = 100
	var abilities: = []
	for ability_name in srd.crew_abilities:
		if ability_name == "Veteran": continue
		var ability = srd.crew_abilities[ability_name]
		if ability.class == "all" or ability.class == type.to_lower():
			starting_ability_options.add_item(ability.name.capitalize(), i)
			ability_choices[i] = ability
			i += 1


	#Set Upgrades (1 and 2 labels, 3 and 4 are choices)
	var upgrades: = []
	for id in srd.crew_upgrades:
		var upgrade = srd.crew_upgrades[id]
		if upgrade.classes.has("all") or upgrade.classes.has(type.to_lower()):
			upgrades.append(upgrade)

	var upgrade1_name = srd.crew_types[type].starting_upgrades[0]
	upgrade1 = srd.crew_upgrades[upgrade1_name]
	upgrade1_label.text = upgrade1.catagory.capitalize() + ": " + upgrade1.name
	var upgrade2_name = srd.crew_types[type].starting_upgrades[1]
	upgrade2 = srd.crew_upgrades[upgrade2_name]
	upgrade2_label.text = upgrade2.catagory.capitalize() + ": " + upgrade2.name

	i = 100
	for upgrade in upgrades:
		if upgrade.name == upgrade1.name or upgrade.name == upgrade2.name:
			continue
		var upgrade_string:String = upgrade.catagory.capitalize() + ": " + upgrade.name
		upgrade3_options.add_item(upgrade_string, i)
		upgrade4_options.add_item(upgrade_string, i)
		upgrade_options[i] = upgrade
		i += 1

	#Setup friendly faction
	var factions = srd.factions
	i = 100
	for faction_name in factions:
		var faction:Dictionary = factions[faction_name]
		var region:String = " - " + faction.region if faction.region else ""
		friendly_faction_options.add_item(faction_name + region, i)
		faction_choices[i] = factions[faction_name]
		i += 1

	#Setup Angry Faction
	i = 100
	for faction_name in factions:
		var faction:Dictionary = factions[faction_name]
		var region:String = " - " + faction.region if faction.region else ""
		angry_faction_options.add_item(faction_name + region, i)
		i += 1

	i = 100
	#Setup Favorite Contact
	for key in srd.contacts:
		var contact = srd.contacts[key]
		if contact.types.has(type):
			var occupation:String = ", " + contact.occupation if contact.occupation else ""
			contact_choices[i] = contact
			favorite_contact_options.add_item(key + occupation, i)
			i += 1

	#Setup Favorite Contact Friendly Contact
	i = 100
	for faction_name in factions:
		var faction:Dictionary = factions[faction_name]
		var region:String = " - " + faction.region if faction.region else ""
		friendly_contact_faction_options.add_item(faction_name + region, i)
		i += 1

	#Setup Angry Contact Friendly Contact
	i = 100
	for faction_name in factions:
		var faction:Dictionary = factions[faction_name]
		var region:String = " - " + faction.region if faction.region else ""
		angry_contact_faction_options.add_item(faction_name + region, i)
		i += 1


func setup_resource(type: String)-> void:
	type = type.to_lower()
	var crew: = CrewConstructor.new()
	var crew_data: = crew.build(type, GameData.srd)
	crew_playbook.setup(crew_data)
	Globals.propagate_set_property_recursive(self, "resource", crew_playbook)


func _on_type_options_item_selected(index: int) -> void:
	var crew_type:String = type_options.get_item_text(index)
	setup_resource(crew_type)
	setup_choices(GameData.srd)
	$MarginContainer/PanelContainer/SetupPages/CrewType/crew_type_description.text = GameData.srd.crew_types[crew_playbook.find("type")].description
	$MarginContainer/PanelContainer/SetupPages/CrewType/Navigation/NextButton.disabled = false


func _on_FinishedButton_pressed() -> void:
	var required_data:Array = [selected_ability, selected_contact, chosen_hunting_ground, selected_angry_faction, selected_friendly_faction, selected_contact_angry_faction, selected_contact_friendly_faction]
	for element in required_data:
		if element == null:
			print("Not all required data is selected")
			return

	crew_playbook.update("coins.available", coins)
	crew_playbook.update("abilities.%s.claimed"%selected_ability.name, true)
	crew_playbook.update("contacts.%s.status"%selected_contact.name, selected_contact.status)
	crew_playbook.update("contacts.%s.notes"%selected_contact.name, "They have been with you since the beginning and helped you establish your crew.")
	crew_playbook.update("hunting_grounds", chosen_hunting_ground)
	selected_angry_faction.status -= 2 if has_influential_contact else 1
	selected_friendly_faction.status += 2 if has_influential_contact else 1

	crew_playbook.add("important_factions.%s.status"%selected_contact_angry_faction.name, selected_contact_angry_faction.status)
	crew_playbook.add("important_factions.%s.status"%selected_contact_friendly_faction.name, selected_contact_friendly_faction.status)
	crew_playbook.add("important_factions.%s.status"%selected_friendly_faction.name, selected_friendly_faction.status)
	crew_playbook.add("important_factions.%s.status"%selected_angry_faction.name, selected_angry_faction.status)
	GameData.crew_playbook_resource = crew_playbook
	Events.emit_signal("popup_finished")
	if on_start_screen:
		get_tree().change_scene_to(Globals.GAME_SCENE)
	else: queue_free()

func _set_coins(value:int)-> void:
	coins = clamp(value, 0, 4)
	var coins_set: = 0
	friendly_faction_interaction_options.set_item_disabled(2, true if coins == 0 else false)
	angry_faction_interaction_options.set_item_disabled(2, true if coins == 0 else false)
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


func _on_hunting_grounds_item_selected(index: int) -> void:
	var id:int = hunting_ground_location_options.get_item_id(index)
	chosen_hunting_ground = hunting_ground_choices[id]
	hunting_grounds_description.text = chosen_hunting_ground.description
	var faction:String = chosen_hunting_ground.faction
	var srd_factions:Dictionary = GameData.srd.factions
	starting_faction = srd_factions[faction]
	faction_name_label.text = starting_faction.name
	faction_description_label.text = starting_faction.description if starting_faction.description else ""



func _on_operation_type_item_selected(index: int) -> void:
	var operation:String = operation_type_options.get_item_text(index)
	crew_playbook.update("operation_types.%s.preferred" % operation, true)


func _on_DealWithFactionOptions_item_selected(index: int) -> void:
	var important_factions:Dictionary = crew_playbook.find("important_factions")
	important_factions[starting_faction.name] = starting_faction
	match index:
		1:
			self.coins = 1
		2:
			self.coins = 0
			crew_playbook.update("important_factions.%s.status"%starting_faction.name, 1)
		3:
			self.coins = 2
			crew_playbook.update("important_factions.%s.status"%starting_faction.name, -1)


func _on_UpgradesChosenButton_pressed() -> void:
	#Add upgrades to playbook
	var selected_upgrades: = [upgrade1, upgrade2, upgrade3, upgrade4]
	for upgrade in selected_upgrades:
		if not upgrade: continue
		crew_playbook.update("upgrades.%s.claimed"%upgrade.name, true)
	_on_NextButton_pressed()


func _on_starting_upgrade3_options_item_selected(index: int) -> void:
	var id:int = upgrade3_options.get_item_id(index)
	var upgrade4_index:int = upgrade4_options.get_item_index(id)
	upgrade3 = upgrade_options[id]
	upgrade_description_label.text = upgrade3.description if upgrade3.description else ""
	upgrade4_options.remove_item(upgrade4_index)


func _on_starting_upgrade4_options_item_selected(index: int) -> void:
	var id:int = upgrade4_options.get_item_id(index)
	var upgrade3_index:int = upgrade3_options.get_item_index(id)
	upgrade4 = upgrade_options[id]
	upgrade_description_label.text = upgrade4.description if upgrade4.description else ""
	upgrade3_options.remove_item(upgrade3_index)


func _on_StartingAbilityOption_item_selected(index: int) -> void:
	var id:int = starting_ability_options.get_item_id(index)
	selected_ability = ability_choices[id]
	ability_description_label.text = selected_ability.description if selected_ability.description else ""


func _on_starting_contact_options_item_selected(index: int) -> void:
	var id:int = favorite_contact_options.get_item_id(index)
	selected_contact = contact_choices[id]
	selected_contact.status = 3
	favorite_contact_label.text = selected_contact.description if selected_contact.description else ""


func _on_friendly_contact_faction_options_item_selected(index: int) -> void:
	var id:int = friendly_contact_faction_options.get_item_id(index)
	selected_contact_friendly_faction = faction_choices[id]
	friendly_contact_faction_description.text = selected_contact_friendly_faction.description if selected_contact_friendly_faction.description else ""


func _on_InfluentialContactToggle_toggled(button_pressed: bool) -> void:
	has_influential_contact = button_pressed


func _on_angry_contact_faction_options_item_selected(index: int) -> void:
	var id:int = angry_contact_faction_options.get_item_id(index)
	selected_contact_angry_faction = faction_choices[id]
	angry_contact_faction_description.text = selected_contact_angry_faction.description if selected_contact_angry_faction.description else ""


func _on_friendly_faction_options_item_selected(index: int) -> void:
	var id:int = friendly_faction_options.get_item_id(index)
	selected_friendly_faction = faction_choices[id]
	friendly_faction_description_label.text = selected_friendly_faction.description if selected_friendly_faction.description else ""


func _on_angry_faction_options_item_selected(index: int) -> void:
	var id:int = angry_faction_options.get_item_id(index)
	selected_angry_faction = faction_choices[id]
	angry_faction_description_label.text = selected_angry_faction.description if selected_angry_faction.description else ""


func _on_friendly_interaction_item_selected(index: int) -> void:
	match index:
		1:
			selected_friendly_faction.status += 1
		2:
			self.coins -= 1
			selected_friendly_faction.status += 2


func _on_angry_interaction_item_selected(index: int) -> void:
	match index:
		1:
			selected_angry_faction.status -= 2
		2:
			self.coins -=1
			selected_angry_faction.status -= 1


func _on_BackButton_pressed() -> void:
	var i:int = 0
	for page in pages:
		page.visible = true if i == page_number - 1 else false
		i += 1
	page_number -= 1
	current_page_number_label.text = str(page_number)


func _on_NextButton_pressed() -> void:
	var i:int = 0
	for page in pages:
		page.visible = true if i == page_number + 1 else false
		i += 1
	page_number += 1
	current_page_number_label.text = str(page_number)
