class_name HighlightArea
extends Area2D

var area_name:String
var area_description:String
var polygon:PoolVector2Array = [] setget _set_polygon
var resource:NetworkedResource
var center:Vector2 setget _set_center
onready var grid:TileMap = get_parent().get_parent()
onready var collison: = $CollisionPolygon2D
onready var light: = $Light2D
onready var light_occluder: = $LightOccluder2D
onready var tween: = $Tween
var testing: = true


func _ready() -> void:
	#Quick testing function to get some correctly formatted strings to store in the srd
	if testing:
		var grid_pos:PoolVector2Array
		for vec in light_occluder.occluder.polygon:
			grid_pos.append(grid.world_to_map(vec))
		print(var2str(grid_pos))
		print(var2str(grid.world_to_map(light.global_position)))


func setup(location:NetworkedResource)-> void:
	visible = false
	resource = location
	location.connect("property_changed", self, "_on_proeprty_changed")
	self.polygon = location.find("boundary")
	self.center = location.find("pos")
	area_name = location.find("name")
	name = area_name if area_name else "area"


func _set_polygon(region:PoolVector2Array)-> void:
	if polygon != region:
		polygon = region
		collison.polygon = polygon
		var occluder_polygon: = OccluderPolygon2D.new()
		occluder_polygon.polygon = polygon
		light_occluder.occluder = occluder_polygon


func _set_center(pos:Vector2)-> void:
	center = pos
	light.global_position = grid.map_to_world(center)


func _on_proeprty_changed(property:String, value)-> void:
	match property:
		"pos":
			self.center = value
		"region":
			pass #TODO

func calculate_center()-> Vector2: #Then you're sure to win
	#This is just fast and dirty take the most extreamly left and most extreamly right and find the center, do the same for the top and bottom and return that vector
	var left:float = 0
	var right:float = 0
	var top:float = 0
	var bottom:float = 0

	for vec in polygon:
		if vec.x < left:
			left = vec.x
		if vec.x > right:
			right = vec.x
		if vec.y < top:
			top = vec.y
		if vec.y > bottom:
			top = vec.y

	var x_center = (left + right) / 2
	var y_center = (top + bottom) / 2
	return Vector2(x_center, y_center)

func highlight_area(region:Area2D)-> void:
	Events.emit_signal("area_highlighted", region)


func _on_area_entered(area: Area2D) -> void:
	var region = self
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


func _on_area_exited(area: Area2D) -> void:
	var region = self
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
