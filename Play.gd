extends Control

export (NodePath) onready var main_viewport = get_node(main_viewport) if main_viewport else null
export (NodePath) onready var mini_viewport= get_node(mini_viewport)if mini_viewport else null
export (NodePath) onready var mini_camera= get_node(mini_camera)if mini_camera else null
export (NodePath) onready var main_camera= get_node(main_camera)if main_camera else null
export (float, 0.1, 20.0) var zoom_factor:= 4.0
export (NodePath) onready var mini_map = get_node(mini_map)
export (NodePath) onready var map = get_node(map) as Map


func _ready() -> void:
	if not main_viewport:
		main_viewport = get_tree().root.get_viewport()
	if not main_camera:
		main_camera = get_tree().root.get_camera()
	print(map)
	map.setup(main_camera)
	mini_map.setup(main_viewport, mini_viewport, main_camera, mini_camera, zoom_factor)
