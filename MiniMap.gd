extends MarginContainer

onready var main_viewport: = get_tree().root.get_viewport()
onready var mini_viewport: = $ViewportContainer/Viewport
onready var mini_camera: = $ViewportContainer/Viewport/MiniMapCamera
export (NodePath) onready var main_camera = get_node(main_camera) as Camera2D
export (float, 0.1, 20.0) var zoom_factor:= 4.0

func _ready() -> void:
	mini_viewport.world_2d = main_viewport.world_2d

func _process(delta: float) -> void:
	if not visible: return

	mini_camera.global_position = main_camera.global_position
	mini_camera.zoom = main_camera.zoom * zoom_factor
