extends HBoxContainer

var resource: NetworkedResource setget _set_resource

signal pressed

func _ready() -> void:
	if resource: Globals.propagate_set_property_recursive(self, "resource", resource)


func _set_resource(value: NetworkedResource)-> void:
	resource = value
	Globals.propagate_set_property_recursive(self, "resource", resource)


func _on_Button_pressed() -> void:
	GameData.active_pc = resource
