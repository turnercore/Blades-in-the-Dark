extends SaveableField

var user_has_selected: = false
var claimed:bool = false
onready var option_button: = $VBoxContainer/StartingAbilityOption
onready var ability_description: = $VBoxContainer/AbilityDescription


func update_playbook_field(ability_key: String)-> void:

	#Set the current claim to false
	claimed = false
	if user_has_selected:
		if playbook.save(playbook_field, claimed):
			playbook.emit_signal("property_changed", playbook_field)
			playbook.emit_changed()

	#Update the new claimed ability
	claimed = true
	playbook_field = "abilities."+ability_key+".claimed"
	if playbook.save(playbook_field, claimed):
			playbook.emit_signal("property_changed", playbook_field)
			playbook.emit_changed()

	ability_description.text = playbook.find("abilities."+ability_key+".description")


func _on_StartingAbilityOption_item_selected(index: int) -> void:
	var key:String = option_button.get_item_text(index).strip_edges().to_lower().replace(" ", "_")
	update_playbook_field(key)
	user_has_selected = true


func _set_playbook(value: Playbook)-> void:
	if playbook:
		playbook.disconnect("property_changed", self, "_on_property_changed")
	playbook = value
	if not value: return
	playbook.connect("property_changed", self, "_on_property_changed")

	while playbook.needs_setup:
		yield(get_tree().create_timer(0.1), "timeout")

	for ability in playbook.abilities:
		if ability == "veteran": continue
		else: option_button.add_item(playbook.abilities[ability].name)

