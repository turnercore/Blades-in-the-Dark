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
	for resource in pins.keys():
		remove_pin(resource)
	pins.clear()

	for location_resource in GameData.location_library.get_catalogue():
		add_pin(location_resource)


func add_pin(pin_resource:NetworkedResource)-> void:
	if pins.has(pin_resource):
		breakpoint
		return

	var pos = pin_resource.find("pos")
	if pos is String:
		pos = str2var(pos)

	var locations = GameData.map.find("locations")

	for loc_id in locations:
		var location = locations[loc_id]
		if location is String:
			location = str2var(location)

	var is_new: = false
	var pin_node: = pin_scene.instance()

	pin_node.location = pin_resource
	add_child(pin_node)
	pin_node.global_position = Globals.map_to_world(pos)
	pins[pin_resource] = pin_node
	if not pin_resource.is_connected("deleted", self, "remove_pin"):
		pin_resource.connect("deleted", self, "remove_pin", [pin_resource])

	#Code to set the name of the node correctly in case nodes are added and deleted in the same frame.
	var pin_nodepath:NodePath = pin_node.get_path()
	yield(get_tree(), "idle_frame")
	if get_node_or_null(pin_nodepath):
		pin_node.name = pin_resource.find("location_name")


func remove_pin(pin_resource:NetworkedResource)-> void:
	if not pins.has(pin_resource):
		print("Pins: pin not found in pins")
		return
	var pin_node:Node = pins[pin_resource]
	if pin_node.location.is_connected("deleted", self, "remove_pin"):
		pin_node.location.disconnect("deleted", self, "remove_pin")
	if pin_resource.is_connected("deleted", self, "remove_pin"):
		pin_resource.disconnect("deleted", self, "remove_pin")
	pin_node.queue_free()
	pins.erase(pin_resource)


func _on_location_added(location_resource:NetworkedResource)-> void:
	if pins.has(location_resource):
		print("location already added")
		return
	else:
		add_pin(location_resource)

func _on_location_removed(location_resource:NetworkedResource)-> void:
	pass
