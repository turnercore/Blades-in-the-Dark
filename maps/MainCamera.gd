extends Camera2D

onready var tween: = $Tween
var is_moving:= false

func _ready() -> void:
	Events.connect("move_camera", self, "_on_move_camera")


func _on_move_camera(pos:Vector2)-> void:
	if is_moving: return
	is_moving = true
	print("moving camera to shortcut")
	tween.interpolate_property(self,
		"global_position",
		null,
		pos,
		Tween.TRANS_LINEAR,
		Tween.EASE_IN_OUT)
	tween.start()
	yield(tween, "tween_all_completed")
	is_moving = false
