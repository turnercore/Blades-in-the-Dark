extends LineEdit

export(String) var property_saved: = "text"
signal property_updated(name, property)

func _on_load(crew_data: Dictionary)->void:
	if self.name in crew_data:
		text = crew_data[self.name]


func _on_updated_data()-> void:
	var updated_value = self.get(property_saved)
	emit_signal("property_updated", name, updated_value)
