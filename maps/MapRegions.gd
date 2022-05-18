class_name MapRegions
extends Node2D

onready var tween: = $Tween
var area_highlighted:String
export (PackedScene) var highlight_area_scene
var regions: = {}


func _ready() -> void:
	var map_regions: = []
	for location in GameData.region_library.get_catalogue():
		map_regions.append(location)
	for region in map_regions:
		create_region(region)
	GameData.region_library.connect("resource_added", self, "_on_region_added")


func reset()-> void:
	for region_resource in regions:
		remove_region(region_resource)
	regions.clear()

	for region_resource in GameData.region_library.get_catalogue():
		create_region(region_resource)


func create_region(region:NetworkedResource)-> void:
	if regions.has(region): return
	if not region.is_connected("deleted", self, "remove_region"):
		region.connect("deleted", self, "remove_region", [region])
	var new_region:Area2D = highlight_area_scene.instance()
	if not new_region.is_connected("area_entered", self, "_on_area_entered"):
		new_region.connect("area_entered", self, "_on_area_entered", [new_region])
		new_region.connect("area_exited", self, "_on_area_exited", [new_region])
	new_region.setup(region)
	add_child(new_region)
	regions[region] = new_region


func remove_region(region:NetworkedResource)-> void:
	if regions.has(region):
		regions[region].queue_free()
		if region.is_connected("deleted", self, "_on_region_deleted"):
			region.disconnect("deleted", self, "_on_region_deleted")


func _on_region_added(region:NetworkedResource)-> void:
	create_region(region)


func _on_region_deleted(region:NetworkedResource)-> void:
	remove_region(region)

func _on_area_entered(area:Area2D, region:Area2D)-> void:
	if area == GameData.local_player.cursor:
		print("local cursor entered area" + region.name)

func _on_area_exited(area:Area2D, region:Area2D)-> void:
	if area == GameData.local_player.cursor:
		print("local cursor left area " + region.name)
