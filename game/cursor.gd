class_name Cursor
extends Area2D

onready var sprite: = $Sprite
var default_texture: Texture = preload("res://Shared/Art/Icons/icon.png")
var default_scale: = Vector2(1, 1)

var current_note_target = null
var current_target = null
var current_target_type:String = "none"

func _process(_delta: float) -> void:
	global_position = get_global_mouse_position()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("left_click"):
		match current_target_type:
			"info":
				print(current_target)
				Events.emit_signal("map_note_clicked", current_note_target)
			_:
				pass



func _on_cursor_area_entered(area: Area2D) -> void:
	if not visible: return

	if area.is_in_group("info"):
		default_texture = sprite.texture
		default_scale = sprite.scale

		sprite.texture = load("res://Shared/Art/Icons/info_icon.png")
		sprite.scale = Vector2(0.05, 0.05)
		current_note_target = area
		current_target_type = "info"


func _on_cursor_area_exited(_area: Area2D) -> void:
	sprite.texture = default_texture
	sprite.scale = default_scale
	current_target = null
	current_target_type = "none"


func _on_VisibilityNotifier2D_viewport_entered(_viewport: Viewport) -> void:
	self.visible = true
	self.monitorable = true
	self.monitoring = true


func _on_VisibilityNotifier2D_viewport_exited(_viewport: Viewport) -> void:
	self.visible = false
	self.monitorable = false
	self.monitoring = false
