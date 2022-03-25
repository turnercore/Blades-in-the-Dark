class_name SaveableField
extends Control

const GROUPS:Array = ["linked_field", "data"]
export(String) var property_saved: = "text"
export(String) onready var playbook_field:String = playbook_field if playbook_field != null else self.name
var linked_nodes:Array

signal property_updated(playbook_field, property)
signal link_updated



func _ready() -> void:
	add_self_to_groups()
	connect_to_self_singal()

	#Wait until everything is loaded
	yield(get_tree(), "idle_frame")
	#Link up fields
	link_same_fields()


func connect_to_self_singal()->void:
	#Buttons
	if has_signal("toggle") and not is_connected("toggle", self, "_on_updated_data"):
		self.connect("toggle", self, "_on_updated_data")
	#Text Edits
	if has_signal("text_changed") and not is_connected("text_changed", self, "_on_updated_data"):
		self.connect("text_changed", self, "_on_updated_data")


func add_self_to_groups()-> void:
	for GROUP in GROUPS:
		if not is_in_group(GROUP):
			add_to_group(GROUP)


func link_same_fields()->void:
	var linked_fields = get_tree().get_nodes_in_group(GROUPS[0])
	for node in linked_fields:
		if node == self: continue
		if node.playbook_field == self.playbook_field and node.has_signal("link_updated"):
			node.connect("link_updated", self, "_on_link_updated")
			linked_nodes.append(node.get_path())


func _on_link_updated(property: String, value)->void:
	set(property, value)


func _on_load(playbook: Playbook)->void:
	var updated_property = playbook.find(playbook_field)

	if updated_property:
		set(property_saved, updated_property)
		emit_signal("link_updated", property_saved, get(property_saved))


func _on_updated_data(_ignored = null)-> void:
	var updated_value = self.get(property_saved)
	emit_signal("property_updated", playbook_field, updated_value)
	emit_signal("link_updated", property_saved, updated_value)
