class_name SaveableField
extends Control

const GROUPS:Array = ["data"]
var playbook setget _set_playbook
export(String) var property: = "text"
#Playbook field should be a dot-notation map to the path
#Example: If you wanted to updated an item is being used
#playbook_field = items.item_name.using
export(String) var playbook_field:String = "" setget _set_playbook_field
export(String) var modular_playbook_field_ending:String


func _ready() -> void:
	connect_to_self_signal()
	if playbook and not playbook.is_connected("property_changed", self, "_on_property_changed"):
		playbook.connect("property_changed", self, "_on_property_changed")


func _set_playbook(value: Playbook)-> void:
	if playbook:
		playbook.disconnect("property_changed", self, "_on_property_changed")
	playbook = value
	if not value: return
	playbook.connect("property_changed", self, "_on_property_changed")
	load_from_playbook()


func _set_playbook_field(value:String)->void:
	playbook_field = value
	if playbook:
		load_from_playbook()


func connect_to_self_signal()->void:
	#Buttons
	if has_signal("toggled") and not is_connected("toggled", self, "_on_updated_data"):
		self.connect("toggled", self, "_on_updated_data")
	#Text Edits
	if has_signal("text_changed") and not is_connected("text_changed", self, "_on_updated_data"):
		self.connect("text_changed", self, "_on_updated_data")
	#Markers
	if has_signal("filled_points_changed") and not is_connected("filled_points_changed", self, "_on_updated_data"):
		self.connect("filled_points_changed", self, "_on_updated_data")


func _on_load(_playbook: Playbook)->void:
	load_from_playbook()


func load_from_playbook()-> void:
	if not playbook: return

	var updated_property = playbook.find(playbook_field)
	if updated_property != null:
		#Ensure the type is correct, so if updating a text field with a number it still works
		if get(property) is String:
			updated_property = str(updated_property)
		if get(property) is int:
			updated_property = int(updated_property)
		if get(property) is float:
			updated_property = float(updated_property)
		if get(property) is bool:
			updated_property = bool(updated_property)

		if get(property) == updated_property: return
		else: set(property, updated_property)


func _on_updated_data(_ignored = null)-> void:
	if not playbook: return
	var updated_value = self.get(property)
	if updated_value == playbook.find(playbook_field):
		return
	if playbook.save(playbook_field, updated_value):
		playbook.emit_signal("property_changed", playbook_field)
		playbook.emit_changed()


func _on_property_changed(field:String)-> void:
	if field == playbook_field:
		load_from_playbook()
