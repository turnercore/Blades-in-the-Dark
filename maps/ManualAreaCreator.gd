extends Area2D


var boundary:PoolVector2Array
var center:Vector2
onready var polygon: = $CollisionPolygon2D
onready var sprite: = $Sprite

func _ready() -> void:
	center = Globals.world_to_map(sprite.global_position)
	var i:int = 1
	for point in polygon.polygon:
		var transformed_point = point + polygon.position
		boundary.append(transformed_point)
		i += 1
	print(var2str(center))
	print(var2str(boundary))
