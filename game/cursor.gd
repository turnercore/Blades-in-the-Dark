extends Area2D

onready var sprite: = $Sprite
var default_texture: Texture = preload("res://Shared/Art/Icons/icon.png")
var default_scale: = Vector2(1, 1)

func _process(_delta: float) -> void:
	global_position = get_global_mouse_position()



func _on_cursor_area_entered(area: Area2D) -> void:
	if not visible: return

	if area.is_in_group("info"):
		default_texture = sprite.texture
		default_scale = sprite.scale

		sprite.texture = load("res://Shared/Art/Icons/info_icon.png")
		sprite.scale = Vector2(0.1, 0.1)


func _on_cursor_area_exited(_area: Area2D) -> void:
	sprite.texture = default_texture
	sprite.scale = default_scale


func _on_VisibilityNotifier2D_viewport_entered(_viewport: Viewport) -> void:
	self.visible = true
	self.monitorable = true
	self.monitoring = true


func _on_VisibilityNotifier2D_viewport_exited(_viewport: Viewport) -> void:
	self.visible = false
	self.monitorable = false
	self.monitoring = false
