class_name HighlightArea
extends Area2D

var area_name:String
var area_description:String
var polygon:PoolVector2Array = [] setget _set_polygon
var resource:NetworkedResource
var center:Vector2 setget _set_center
onready var collison: = $CollisionPolygon2D
onready var light: = $Light2D
onready var light_occluder: = $LightOccluder2D
onready var tween: = $Tween


#Just some test code to see if loading the data works.
#func _ready() -> void:
#	var poolvecstr:String = "PoolVector2Array( -1677, -1388, -1519.16, -178.948, -1173.93, 783.41, -905.04, 813.463, 432.783, 860.7, 507.802, 855.994, 1373.24, -21.625, 1331.43, -68.789, 995.193, -1031.11, 360.434, -1349.6, -1730.28, -1427.78 )"
#	var location:NetworkedResource = NetworkedResource.new()
#	var boundary:PoolVector2Array = str2var(poolvecstr)
#	var pos:Vector2 = str2var("Vector2( 232, -482 )")
#	var test_loc_data:Dictionary = {
#		"boundary": boundary,
#		"pos": pos,
#		"name": "Brightstone"
#	}
#	location.setup(test_loc_data)
#	setup(location)


func setup(location:NetworkedResource)-> void:
	collison = $CollisionPolygon2D
	light = $Light2D
	light_occluder = $LightOccluder2D
	tween = $Tween
	visible = false
	resource = location
	location.connect("property_changed", self, "_on_property_changed")
	self.polygon = location.find("boundary")
	self.center = location.find("pos")
	area_name = location.find("name")
	name = area_name if area_name else "area"


func _set_polygon(region:PoolVector2Array)-> void:
	collison.polygon = region
	var occluder_polygon: = OccluderPolygon2D.new()
	occluder_polygon.polygon = region
	occluder_polygon.closed = false
	light_occluder.occluder = occluder_polygon


func _set_center(pos:Vector2)-> void:
	if not Globals.is_inside_tree():
		yield(Globals, "tree_entered")
	if not self.is_inside_tree():
		yield(self, "tree_entered")
	center = pos
	self.global_position = Globals.map_to_world(center)
	light.global_position = Globals.map_to_world(center)


func _on_property_changed(property:String, value)-> void:
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
	if area is Cursor and not area.is_remote:
		visible = true
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
		highlight_area(self)


func _on_area_exited(area: Area2D) -> void:
	if area is Cursor and not area.is_remote:
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
		visible = false
