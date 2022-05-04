class_name SaveableField
extends Control

const GROUPS:Array = ["data"]
var resource setget _set_resource
export(String) var property: = "text"
#Playbook field should be a dot-notation map to the path
#Example: If you wanted to updated an item is being used
#playbook_field = items.item_name.using
export(String) var field:String = "" setget _set_field
export(String) var modular_field_ending:String


func _ready() -> void:
	connect_to_self_signal()


func _set_resource(value: NetworkedResource)-> void:
	if resource:
		resource.disconnect("property_changed", self, "_on_property_changed")
	resource = value
	if not value: return
	resource.connect("property_changed", self, "_on_property_changed")
	load_from_resource(resource)


func _set_field(value:String)->void:
	field = value
	if resource:
		load_from_resource(resource)


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
	#OptionDropdowns
	if has_signal("item_selected") and not is_connected("item_selected", self, "_on_updated_data"):
		self.connect("item_selected", self, "_on_updated_data")


func _on_load(resource: NetworkedResource)->void:
	load_from_resource(resource)


func load_from_resource(load_resource:NetworkedResource)-> void:
	resource = load_resource
	if not resource: return

	#Don't want option buttons to update from resource
	if self.has_signal("item_selected"):
		return

	var updated_property = resource.find(field)

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
		breakpoint
		if get(property) == updated_property: return
		else: set(property, updated_property)


func _on_updated_data(data = null)-> void:
	if not resource: return
	var updated_value
	updated_value = str(self.get(property)) if property == "text" else self.get(property)
	if updated_value == resource.find(field):
		return
	resource.update(field, updated_value)


func _on_property_changed(path:String, value)-> void:
	if path == field:
		if typeof(value) != typeof(get(property)) and value is String:
			value = str2var(value)
		if get(property) != value:
			set(property, value)

