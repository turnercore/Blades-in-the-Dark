extends TextureRect

var _previous_mouse_position = Vector2()
var _is_dragging = false
var pos: = Vector2.ZERO setget _set_pos
var data: = {}

export (NodePath) onready var grid = get_node(grid) as TileMap
export (PackedScene) onready var map_pin_creation

func _ready():
	pos = grid.world_to_map(get_global_mouse_position())


func _set_pos(value)-> void:
	pos = str2var(value)
	data.pos = var2str(value)


func _process(delta):
	if not grid: return
	if _is_dragging:
		var mouse_delta = _previous_mouse_position - grid.world_to_map(get_global_mouse_position())
		if mouse_delta.x != 0 or mouse_delta.y != 0:
			_previous_mouse_position = grid.world_to_map(get_global_mouse_position())
		rect_position -= mouse_delta * grid.cell_size


func _on_gui_input(event: InputEvent) -> void:
	if not grid: return
	if event.is_action_pressed("left_click"):
		_is_dragging = true
		rect_scale = Vector2(1.5, 1.5)
		_previous_mouse_position = grid.world_to_map(get_global_mouse_position())
	if event.is_action_released("left_click"):
		rect_scale = Vector2(1, 1)
		_is_dragging = false
		if _previous_mouse_position != pos:
			pos = grid.world_to_map(get_global_mouse_position())
			Events.emit_signal("pin_dropped", self)
