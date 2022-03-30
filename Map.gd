class_name Map
extends Control

export (float) var scroll_speed:float = 500
onready var tween: = $Tween
export (NodePath) onready var camera
var zoom_level: float
var focused: bool = true



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_connect_mouse_entered_recursive(self)

	if camera:
		camera = get_node_or_null(camera) if camera else null
		zoom_level = camera.zoom.x
	Events.connect("map_scroll_speed_changed", self, "_on_map_scroll_speed_changed")


#func _draw() -> void:
#	if not camera: return
#
#	var rect: = Rect2(camera.global_position, get_tree().root.get_viewport().size * 2)
#	var color: = Color.black
#	draw_rect(rect, color, false, 25.0, false)

func _connect_mouse_entered_recursive(node: Node)-> void:
	if node.has_signal("mouse_entered"):
		node.connect("mouse_entered", self, "_on_Map_mouse_entered")
	if node.has_signal("mouse_exited"):
		node.connect("mouse_exited", self, "_on_Map_mouse_exited")

	for child in node.get_children():
		_connect_mouse_entered_recursive(child)


func _process(delta: float) -> void:
	if not focused: return
	if not camera: return

	if Input.is_action_pressed("ui_down"):
		scroll_down(delta)
	if Input.is_action_pressed("ui_up"):
		scroll_up(delta)
	if Input.is_action_pressed("ui_left"):
		scroll_left(delta)
	if Input.is_action_pressed("ui_right"):
		scroll_right(delta)
	if Input.is_action_pressed("zoom_in"):
		zoom_in(delta)
	if Input.is_action_pressed("zoom_out"):
		zoom_out(delta)


func scroll_up(delta: float)->void:
	camera.position.y -= scroll_speed * delta * clamp(zoom_level * zoom_level, .30, 8)


func scroll_down(delta: float)-> void:
	camera.position.y += scroll_speed * delta * clamp(zoom_level * zoom_level, .30, 8)


func scroll_right(delta: float)-> void:
	camera.position.x += scroll_speed * delta * clamp(zoom_level * zoom_level, .30, 8)


func scroll_left(delta: float) -> void:
	camera.position.x -= scroll_speed * delta * clamp(zoom_level * zoom_level, .30, 8)


func zoom_in(delta: float)-> void:
	camera.zoom *= 1 - delta
	zoom_level = camera.zoom.x


func zoom_out(delta:float)->void:
	camera.zoom *= 1 + delta
	zoom_level = camera.zoom.x


func _on_map_scroll_speed_changed(new_scroll_speed: float) -> void:
	scroll_speed = new_scroll_speed


func _on_Map_mouse_entered() -> void:
	print("map lost focus")
	focused = true


func _on_Map_mouse_exited() -> void:
	print("map focused")
	focused = false
