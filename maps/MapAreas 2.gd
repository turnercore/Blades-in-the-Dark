extends Node2D

onready var tween: = $Tween
var area_highlighted:String
export (PackedScene) var highlight_area_scene
var areas: = {}


func _ready() -> void:
	var map_regions: = []
	for location in GameData.region_library.get_catalogue():
		map_regions.append(location)

	for region in map_regions:
		create_region(region)

	GameData.region_library.connect("resource_added", self, "_on_region_added")



func create_region(region:NetworkedResource)-> void:
	var new_region:Area2D = highlight_area_scene.instance()
	new_region.connect("area_entered", self, "_on_area_entered", [new_region])
	new_region.connect("area_exited", self, "_on_area_exited", [new_region])
	new_region.setup(region)
	add_child(new_region)
	areas[region] = new_region


func remove_region(region:NetworkedResource)-> void:
	if areas.has(region):
		areas[region].queue_free()
		region.disconnect("deleted", self, "_on_region_deleted")


func _on_region_added(region:NetworkedResource)-> void:
	create_region(region)


func _on_region_deleted(region:NetworkedResource)-> void:
	remove_region(region)