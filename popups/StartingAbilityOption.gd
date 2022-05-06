extends SaveableField

var user_has_selected: = false
var claimed:bool = false
onready var option_button: = $VBoxContainer/StartingAbilityOption
onready var ability_description: = $VBoxContainer/ability_description


func update_playbook_field(ability_key: String)-> void:
	#Set the current claim to false
#	claimed = false
#	if user_has_selected:
#		if playbook.save(playbook_field, claimed):
#			playbook.emit_signal("property_changed", playbook_field)
#			playbook.emit_changed()
#
#	#Update the new claimed ability
#	claimed = true
#	field = "abilities."+ability_key+".claimed"
#	if resource.find(field, "claimed"):
#			resource.emit_signal("property_changed", playbook_field)
#			playbook.emit_changed()

	ability_description.text = resource.find("abilities."+ability_key+".description")


func _on_StartingAbilityOption_item_selected(index: int) -> void:
	var key:String = option_button.get_item_text(index).strip_edges().to_lower().replace(" ", "_")
	update_playbook_field(key)
	user_has_selected = true


func _set_resource(value: NetworkedResource)-> void:
	if resource:
		resource.disconnect("property_changed", self, "_on_property_changed")
	resource = value
	if not value: return
	resource.connect("property_changed", self, "_on_property_changed")

	var abilities:Dictionary = resource.get_property("abilities")

	for ability in abilities:
		if ability == "veteran": continue
		else: option_button.add_item(abilities[ability].name)

