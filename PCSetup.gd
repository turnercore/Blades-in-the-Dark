extends PopupScreen

export (NodePath) onready var current_page_number_label = get_node(current_page_number_label) as Label
export (NodePath) onready var total_page_number_label = get_node(total_page_number_label) as Label
export (NodePath) onready var type_short_description = get_node(type_short_description) as Label
export (NodePath) onready var type_long_description = get_node(type_long_description) as Label
export (NodePath) onready var type_options = get_node(type_options) as OptionButton
export (NodePath) onready var heritage_options = get_node(heritage_options) as OptionButton
export (NodePath) onready var heritage_description = get_node(heritage_description) as Label
export (NodePath) onready var background_options = get_node(background_options) as OptionButton
export (NodePath) onready var background_description = get_node(background_description) as Label
export (NodePath) onready var vice_options = get_node(vice_options) as OptionButton
export (NodePath) onready var vice_description = get_node(vice_description) as Label
export (NodePath) onready var vice_purveyor_options = get_node(vice_purveyor_options) as OptionButton
export (NodePath) onready var vice_purveyor_description = get_node(vice_purveyor_description) as Label
export (NodePath) onready var ability_options = get_node(ability_options) as OptionButton
export (NodePath) onready var ability_description = get_node(ability_description) as Label
export (NodePath) onready var friend_options = get_node(friend_options) as OptionButton
export (NodePath) onready var friend_description = get_node(friend_description) as Label
export (NodePath) onready var rival_options = get_node(rival_options) as OptionButton
export (NodePath) onready var rival_description = get_node(rival_description) as Label
export (NodePath) onready var look_text_edit = get_node(look_text_edit) as TextEdit
export (NodePath) onready var action_options1 = get_node(action_options1) as OptionButton
export (NodePath) onready var action_options2 = get_node(action_options2) as OptionButton
export (NodePath) onready var action_options3 = get_node(action_options3) as OptionButton
export (NodePath) onready var action_options4 = get_node(action_options4) as OptionButton

onready var pages: Array = $MarginContainer/PanelContainer/SetupPages.get_children()
var current_page:int = 0 setget _set_current_page

var pc_data:Dictionary
var pc_type:String
var heritage_notes:String
var type_choices: = {}
var heritage_choices: = {}
var background_choices: = {}
var vice_choices: = {}
var vice_purveyor_choices: = {}
var contact_choices: = {}
var chosen_friend
var old_rival_index:int = -100
var old_friend_index:int = -100
var friend_notes
var chosen_rival
var rival_notes
var chosen_vice_purveyor
var vice_purveyor_notes
var ability_choices: = {}
var chosen_ability
var chosen_action_dots: = {}
var action_choices: = {}


signal player_type_chosen
signal finished


func _ready() -> void:
	self.current_page = 0
	for page in pages:
		page.visible = false
	pages.front().visible = true
	total_page_number_label.text = str(pages.size())
	setup(GameData.srd)


func setup(srd:Dictionary)-> void:
	#Setup Scoundrel Types
	var id:int = 100
	for type in srd.pc_types:
		var item:String = str(type)
		item = item.capitalize()
		type_options.add_item(item, id)
		type_choices[id] = GameData.srd.pc_types[type]
		id += 1

	#Wait until class is picked to set up rest of the pages
	yield(self, "player_type_chosen")
	#Player type is chosen now we can continue setting up options

	#Setup Heritages
	setup_option_button(heritage_options, heritage_choices, srd, "heritages")

	#Setup Backgrounds
	setup_option_button(background_options, background_choices, srd, "backgrounds")

	#SetupActionDots
	setup_option_button(action_options1, action_choices, srd, "actions")
	setup_option_button(action_options2, action_choices, srd, "actions")
	setup_option_button(action_options3, action_choices, srd, "actions")
	setup_option_button(action_options4, action_choices, srd, "actions")
	disable_action_dots()

	#Setup Abilities
	id = 100
	for ability_name in srd.character_abilities:
		if ability_name == "Veteran": continue
		if srd.character_abilities[ability_name].class.to_lower() == pc_type.to_lower():
			ability_options.add_item(ability_name, id)
			ability_choices[id] = srd.character_abilities[ability_name]
			id += 1

	#Setup Vices
	setup_option_button(vice_options, vice_choices, srd, "vices")

	#Setup friend and rival
	id = 100
	for key in srd.contacts:
		var contact = srd.contacts[key]
		if contact.types.has(pc_type) or contact.types.has("all"):
			contact_choices[id] = contact
			id += 1

	for i in contact_choices:
		var contact = contact_choices[i]
		friend_options.add_item(contact.name, i)
		rival_options.add_item(contact.name, i)


func setup_option_button(option_button:OptionButton, choice_storage:Dictionary, srd:Dictionary, srd_field:String)-> void:
	var id:int = 100
	if srd[srd_field] is Array:
		for field in srd[srd_field]:
			var item:String = str(field.name).capitalize()
			option_button.add_item(item, id)
			choice_storage[id] = field
			id += 1
	elif srd[srd_field] is Dictionary:
		for key in srd[srd_field]:
			var selected = srd[srd_field][key]
			var item:String = str(selected.name).capitalize()
			option_button.add_item(item, id)
			choice_storage[id] = selected
			id += 1


func add_playbook()-> void:
	#First add chosen things that couldn't be added before to the playbook data, then setup the playbook, create the resource, and add it to gamedata
	#Add selected ability
	pc_data.abilities[chosen_ability.name] = chosen_ability
	#Add selected friend, adjust status
	chosen_friend.status = 2
	pc_data.contacts[chosen_friend.name] = chosen_friend
	#Add selected rival, adjust status
	chosen_rival.status = -2
	pc_data.contacts[chosen_rival.name] = chosen_rival
	#Add selected vice purveyor, adjust status
	chosen_vice_purveyor.status = 2
	pc_data.contacts[chosen_vice_purveyor.name] = chosen_vice_purveyor
	#Set stats, get starting stats from srd and add in improved stats
	for stat in chosen_action_dots:
		if stat in pc_data.stats:
			pc_data.stats[stat].level += chosen_action_dots[stat].level
			if pc_data.stats[stat].level > 2:
				print("ERROR SETTING STAT TO MORE THAN 2")

	var pc_playbook:NetworkedResource = GameData.pc_library.add(pc_data)
	GameData.active_pc = pc_playbook


func disable_action_dots()-> void:
	var maxed_out_stats: = []

	for stat in pc_data.stats:
		if pc_data.stats[stat].level >= 2:
			maxed_out_stats.append(stat)

	for stat in chosen_action_dots:
		if stat in pc_data.stats:
			if pc_data.stats[stat].level + chosen_action_dots[stat].level >= 2:
				maxed_out_stats.append(stat)

	for stat in maxed_out_stats:
		for id in action_choices:
			if maxed_out_stats.has(action_choices[id].name):
				action_options1.set_item_disabled(action_options1.get_item_index(id), true)
				action_options2.set_item_disabled(action_options1.get_item_index(id), true)
				action_options3.set_item_disabled(action_options1.get_item_index(id), true)
				action_options4.set_item_disabled(action_options1.get_item_index(id), true)
			else:
				action_options1.set_item_disabled(action_options1.get_item_index(id), false)
				action_options2.set_item_disabled(action_options1.get_item_index(id), false)
				action_options3.set_item_disabled(action_options1.get_item_index(id), false)
				action_options4.set_item_disabled(action_options1.get_item_index(id), false)


func _on_BackNextButtons_next() -> void:
	self.current_page += 1


func _on_BackNextButtons_back() -> void:
	self.current_page -= 1


func _set_current_page(value:int)-> void:
	value = int(clamp(value, 0, pages.size()-1))
	current_page_number_label.text = str(value + 1)
	pages[current_page].visible = false
	pages[value].visible = true
	current_page = value


func _on_BackNextButtons_finished() -> void:
	add_playbook()
	Events.emit_signal("popup_finished")
	hide()


func _on_pc_type_item_selected(index: int) -> void:
	var id:int = type_options.get_item_id(index)
	pc_type = type_choices[id].name

	type_short_description.text = type_choices[id].short_description
	type_long_description.text = type_choices[id].long_description
	#Resets up pc_data to be dependent on what type is chosen.
	var pc_constructor: = PCConstructor.new()
	pc_data = pc_constructor.build(pc_type, GameData.srd)


func _on_BackNextButtons_finished_page(page_name:String) -> void:
	if page_name == "player_type":
		emit_signal("player_type_chosen")


func _on_heritage_notes_text_changed(new_text: String) -> void:
	pc_data.heritage.notes = new_text


func _on_heritage_options_item_selected(index: int) -> void:
	var id:int = heritage_options.get_item_id(index)
	var choice:Dictionary = heritage_choices[id]
	heritage_description.text = choice.description
	pc_data.heritage.description = choice.description
	pc_data.heritage.name = choice.name


func _on_vice_options_item_selected(index: int)-> void:
	var id:int = vice_options.get_item_id(index)
	vice_purveyor_options.clear()
	vice_purveyor_description.text = ""
	vice_purveyor_choices.clear()
	var vice:String = vice_choices[id].name.to_lower()
	pc_data.vice.type = vice
	var i: int = 100
	for contact_name in GameData.srd.contacts:
		var contact = GameData.srd.contacts[contact_name]
		if contact.types.has(vice):
			vice_purveyor_options.add_item(contact_name.capitalize(), i)
			vice_purveyor_choices[i] = contact
			i += 1


func _on_background_notes_text_changed(new_text: String) -> void:
	pc_data.background.notes = new_text


func _on_background_options_item_selected(index: int) -> void:
	var id:int = background_options.get_item_id(index)
	background_description.text = background_choices[id].description
	pc_data.background.name = background_choices[id].name
	pc_data.background.description = background_choices[id].description


func _on_ability_options_item_selected(index: int) -> void:
	var id:int = background_options.get_item_id(index)
	ability_description.text = ability_choices[id].description
	chosen_ability = ability_choices[id]


func _on_friend_notes_text_changed(new_text: String) -> void:
	friend_notes = new_text


func _on_friend_options_item_selected(index: int) -> void:
	var id:int = friend_options.get_item_id(index)
	friend_description.text = contact_choices[id].description if contact_choices[id].description else ""
	chosen_friend = contact_choices[id] # Replace with function body.
	var rival_index:int = rival_options.get_item_index(id)
	if old_rival_index > -1:
		rival_options.set_item_disabled(old_rival_index, false)
	rival_options.set_item_disabled(rival_index, true)
	old_rival_index = rival_index


func _on_rival_options_item_selected(index: int) -> void:
	var id:int = rival_options.get_item_id(index)
	rival_description.text = contact_choices[id].description if contact_choices[id].description else ""
	chosen_rival = contact_choices[id] # Replace with function body.
	var friend_index:int = friend_options.get_item_index(id)
	if old_friend_index > -1:
		friend_options.set_item_disabled(old_friend_index, false)
	friend_options.set_item_disabled(friend_index, true)
	old_friend_index = friend_index # Replace with function body.


func _on_rival_notes_text_changed(new_text: String) -> void:
	rival_notes = new_text


func _on_vice_purveyor_notes_text_changed(new_text: String) -> void:
	vice_purveyor_notes = new_text


func _on_vice_notes_text_changed(new_text: String) -> void:
	pc_data.vice.description = new_text



func _on_Look_text_changed() -> void:
	pc_data.look = look_text_edit.text


func _on_Alias_text_changed(new_text: String) -> void:
	pc_data.alias = new_text


func _on_Name_text_changed(new_text: String) -> void:
	if pc_data.name != new_text:
		pc_data.name = new_text


func _on_action_dot_item_selected(index: int, node:String) -> void:
	var id:int = action_options1.get_item_id(index)
	var action = action_choices[id]
	#Remove any previously entered points
	for action_name in chosen_action_dots:
		if chosen_action_dots[action_name].nodes.has(node):
			chosen_action_dots[action_name].nodes.erase(node)
			chosen_action_dots[action_name].level -= 1

	if action.name in chosen_action_dots and "level" in chosen_action_dots[action.name] and "nodes" in chosen_action_dots[action.name]:
		chosen_action_dots[action.name].level += 1
		chosen_action_dots[action.name].nodes.append(node)
	else:
		chosen_action_dots[action.name] = {
			"level": 1,
			"nodes": [node]
		}
	disable_action_dots()


func _on_vice_purveyor_options_item_selected(index: int) -> void:
	var id:int = vice_purveyor_options.get_item_id(index)
	var purveyor = vice_purveyor_choices[id]
	breakpoint
	chosen_vice_purveyor = purveyor
