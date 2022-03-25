extends Control

export(String) var property_saved: = "text"
signal property_updated(name, property)
signal link_updated

func _ready() -> void:
	link_same_fields()


func link_same_fields()->void:
	var linked_fields = get_tree().get_nodes_in_group("linked_field")
	for node in linked_fields:
		if node.name == self.name and node.has_signal("link_updated"):
			node.connect("link_updated", self, "_on_link_updated")


func _on_link_updated(property: String, value)->void:
	set(property, value)


func _on_load(crew_data: Dictionary)->void:
	if self.name in crew_data:
		set(property_saved, crew_data[self.name])


func _on_updated_data(_ignored = null)-> void:
	var updated_value = self.get(property_saved)
	emit_signal("property_updated", name, updated_value)
	emit_signal("link_updated", property_saved, updated_value)
