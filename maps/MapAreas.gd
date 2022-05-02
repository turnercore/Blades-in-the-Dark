extends Node2D

onready var tween: = $Tween
var area_highlighted:String
export (PackedScene) var highlight_area_scene
var areas: = {}


func _ready() -> void:
	var map_regions: = []
	for location in GameData.location_library.get_catalogue():
		if location.has("region"):
			map_regions.append(location)

	for region in map_regions:
		create_region(region)
		region.connect("deleted", self, "_on_region_deleted", [region])



func create_region(location:NetworkedResource)-> void:
	var new_region:Area2D = highlight_area_scene.instance()
	new_region.connect("area_entered", self, "_on_area_entered", [new_region])
	new_region.connect("area_exited", self, "_on_area_exited", [new_region])
	new_region.setup(location)
	add_child(new_region)
	areas[location] = new_region


func highlight_area(region:Area2D)-> void:
	Events.emit_signal("area_highlighted", region)


func _on_area_entered(area: Area2D, region: Area2D) -> void:
	if area is Cursor and not area.is_remote:
		region.visible = true
		var light: = region.get_node("Light2D") as Light2D

		tween.interpolate_property(
			light,
			"shadow_color",
			null,
			Color(0,0,0,0.75),
			0.25,
			Tween.TRANS_QUAD,
			Tween.EASE_IN_OUT
		)
		tween.start()
		highlight_area(region)


func _on_area_exited(area: Area2D, region: Area2D) -> void:
	if area is Cursor and not area.is_remote:
		var light: = region.get_node("Light2D") as Light2D
		tween.interpolate_property(
			light,
			"shadow_color",
			null,
			Color(0,0,0,0),
			0.15,
			Tween.TRANS_QUAD,
			Tween.EASE_IN_OUT
		)
		tween.start()
		yield(tween, "tween_completed")
		region.visible = false

func _on_region_deleted(region:NetworkedResource)-> void:
	if areas.has(region):
		areas[region].queue_free()
		region.disconnect("deleted", self, "_on_region_deleted")
