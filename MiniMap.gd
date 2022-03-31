extends MarginContainer

var _main_viewport: Viewport
var _mini_viewport: Viewport
var _mini_camera: Camera2D
var _main_camera: Camera2D
var _zoom_factor: float

func _ready() -> void:
	set_process(false)



func setup(main_viewport: Viewport, mini_viewport: Viewport, main_camera:Camera2D, mini_camera: Camera2D, zoom_factor:float = 4.0)-> void:
	_main_viewport = main_viewport
	_mini_viewport = mini_viewport
	_main_camera = main_camera
	_mini_camera = mini_camera
	_zoom_factor = zoom_factor

	if _main_viewport == null or _mini_viewport == null or _main_camera == null or _mini_camera == null:
		print("Issue setting up minimap, something isn't connected properly")
		print(_main_viewport)
		print(_mini_viewport)
		print(_main_camera)
		print(_mini_camera)
		return
	else:
		_mini_viewport.world_2d = _main_viewport.world_2d
		set_process(true)







func _process(delta: float) -> void:
	if not visible: return

	_mini_camera.global_position = _main_camera.global_position
	_mini_camera.zoom = _main_camera.zoom * _zoom_factor
