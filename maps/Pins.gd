class_name Pins
extends Node2D

const pin_scene: = preload("res://maps/MapNote.tscn")
var pins:= {}


func _ready()-> void:
	Events.connect("pin_dropped", self, "_on_map_pin_dropped")
	GameData.location_library.connect("resource_added", self, "_on_location_added")
	GameData.location_library.connect("resource_removed", self, "_on_location_removed")
	reset()


func reset()-> void:
	for pos in pins:
		remove_pin(pos)
	pins.clear()

	for location_resource in GameData.location_library.get_catalogue():
		add_pin(location_resource)


func add_pin(pin_resource:NetworkedResource)-> void:
	var pos = pin_resource.find("pos")
	if pos is String:
		pos = str2var(pos)
	if pins.has(pos): return

	var locations = GameData.map.find("locations")

	for loc_id in locations:
		var location = locations[loc_id]
		if location is String:
			location = str2var(location)

	var is_new: = false
	var pin_node: = pin_scene.instance()

	pin_node.location = pin_resource
	add_child(pin_node)
	pin_node.global_position = Globals.grid.map_to_world(pos)
	pins[pin_resource] = pin_node
	if not pin_resource.is_connected("deleted", self, "remove_pin"):
		pin_resource.connect("deleted", self, "remove_pin", [pos])


func remove_pin(pos:Vector2)-> void:
	for pin_resource in pins:
		var pin_resource_pos = pin_resource.find("pos")
		if pin_resource_pos is String:
			pin_resource_pos = str2var(pin_resource_pos)
		if pos == pin_resource_pos:
			var pin_node:Node = pins[pin_resource]
			if pin_node.location.is_connected("deleted", self, "remove_pin"):
				pin_node.location.disconnect("deleted", self, "remove_pin")
			pin_node.queue_free()
			pins.erase(pos)


func _on_location_added(location_resource:NetworkedResource)-> void:
	var pos = location_resource.find("pos")
	if pins.has(pos):
		return
	else:
		add_pin(location_resource)

func _on_location_removed(location_resource:NetworkedResource)-> void:
	pass
