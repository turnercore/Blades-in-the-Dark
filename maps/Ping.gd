extends Node2D

const MAX_RADIUS:float = 300.0
const DURATION:float = 0.75

var pos:Vector2 = Vector2(10000, 10000)
var radius:float = 0.0
var width:float = 20.0
var color: = Color.coral
var resolution:int = 100
onready var tween: = $Tween

signal ping_finished

func _ready() -> void:
#	if pos == Vector2(10000, 10000):
#		pos = get_global_mouse_position()
	tween.connect("tween_all_completed", self, "_on_finished_ping")
	tween.interpolate_property(
		self,
		"radius",
		null,
		MAX_RADIUS,
		DURATION,
		Tween.TRANS_CUBIC,
		Tween.EASE_IN
	)
	tween.interpolate_property(
		self,
		"width",
		null,
		1,
		DURATION,
		Tween.TRANS_LINEAR,
		Tween.EASE_IN
		)
	tween.start()


func _draw() -> void:
	draw_arc(pos,radius, 0, 2*PI, resolution, color, width, true)


func _process(delta: float) -> void:
	update()

func _on_finished_ping()-> void:
	emit_signal("ping_finished")
	var data: = {}
	data[pos] = pos
	data[color] = color
	if GameData.online:
		var result:int = NetworkTraffic.send_data_async(NetworkTraffic.OP_CODES.PLAYER_PING, data)
		if result != OK:
			print("ERROR SENDING PING ACROSS NETWORK")
	queue_free()
