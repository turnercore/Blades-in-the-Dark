extends Control

export (NodePath) onready var main_viewport = get_node(main_viewport) if main_viewport else null
export (NodePath) onready var mini_viewport= get_node(mini_viewport)if mini_viewport else null
export (NodePath) onready var mini_camera= get_node(mini_camera)if mini_camera else null
export (float, 0.1, 20.0) var zoom_factor:= 4.0
export (NodePath) onready var mini_map = get_node(mini_map)
export (NodePath) onready var map = get_node(map) as Map
onready var main_camera= map.camera

func _ready() -> void:
	if not main_viewport:
		main_viewport = get_tree().root.get_viewport()
	if not main_camera:
		main_camera = get_tree().root.get_camera()
#	map.setup(main_camera)
	mini_map.setup(main_viewport, mini_viewport, main_camera, mini_camera, zoom_factor)
#	Events.connect("main_screen_changed", self, "_on_main_screen_changed")

#func _on_main_screen_changed(screen: String)->void:
#	screen = screen.to_lower()
#	if screen == "main":
#		self.visible = true
#		$PlayLayer/PlayControls.visible = true
#		map.unfocused = false
#	else:
#		self.visible = false
#		$PlayLayer/PlayControls.visible = false
#		map.unfocused = true
