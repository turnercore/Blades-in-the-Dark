extends Node2D

var points: PoolVector2Array
var point:Vector2 setget _set_point
var width:float = 250.0
var color: = Color.black

func _process(delta):
	if points.size() == 1:
		points.append(get_global_mouse_position())
	if points.size() >= 2:
		points.set(points.size()-1, get_global_mouse_position())
		update()


func _draw():
	if points.size() >= 2:
		draw_multiline(points, color, width, true)

func _set_point(value:Vector2)-> void:
	point = value
	points.append(point)
