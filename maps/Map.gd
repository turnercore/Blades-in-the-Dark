class_name Map
extends Node2D

const map_note_scene: = preload("res://maps/MapNote.tscn")

const DEFAULT_LOCATION_DATA: = {
	"pos": Vector2.ZERO,
	"icon": "",
	"location_name": "",
	"description": ""
}

export (float) var scroll_speed:float = 500
export (NodePath) onready var tween = get_node(tween) as Tween
export (NodePath) onready var cursor = get_node(cursor) as Cursor
export (NodePath) onready var notes = get_node(notes) as Node2D
export (NodePath) onready var camera = get_node(camera) as Camera2D
export (NodePath) onready var map_texture = get_node(map_texture) as TextureRect
export (NodePath) onready var grid = get_node(grid) as TileMap
export (PackedScene) var player_cursor_scene
var zoom_level: float
var unfocused: = false
onready var player_cursors: = [cursor]
var notes_added: = []
var pins:= {}

func _ready() -> void:
	Globals.grid = grid
	connect_to_events()
	if GameData.map:
		load_map(GameData.map)

	if ServerConnection.is_connected_to_server:
		add_new_player_cursors(ServerConnection.presences)

	zoom_level = camera.zoom.x


func connect_to_events()-> void:
	GameData.connect("map_loaded", self, "_on_map_loaded")
	Events.connect("map_scroll_speed_changed", self, "_on_map_scroll_speed_changed")
	Events.connect("popup", self, "_on_popup")
	Events.connect("all_popups_finished", self, "_on_all_popups_finished")
	Events.connect("pin_dropped", self, "_on_map_pin_dropped")
	ServerConnection.connect("match_joined", self, "_on_match_joined")
	ServerConnection.connect("presences_changed", self, "_on_presences_changed")
	GameData.location_library.connect("resource_added", self, "_on_location_added")
	GameData.location_library.connect("resource_removed", self, "_on_location_removed")


func _process(delta: float) -> void:
	if unfocused: return
	if Input.is_action_pressed("display_map_coords"):
		var info_string:= "Map Grid Coords: \n" + str(Globals.convert_to_grid(get_global_mouse_position()))
		Events.emit_signal("info_broadcasted", info_string)
	if Input.is_action_pressed("ui_down"):
		scroll_down(delta)
	if Input.is_action_pressed("ui_up"):
		scroll_up(delta)
	if Input.is_action_pressed("ui_left"):
		scroll_left(delta)
	if Input.is_action_pressed("ui_right"):
		scroll_right(delta)
	if Input.is_action_pressed("zoom_in") or Input.is_action_just_released("zoom_in"):
		zoom_in(delta)
	if Input.is_action_pressed("zoom_out") or Input.is_action_just_released("zoom_out"):
		zoom_out(delta)


func remove_pin(pos:Vector2)-> void:
	if pins.has(pos):
		pins[pos].queue_free()
		pins.erase(pos)

func add_pin(pos:Vector2, data: = {})-> void:
	var grid_mouse_pos:Vector2 = Globals.convert_to_grid(get_global_mouse_position())
	for location in GameData.map.locations:
		if grid_mouse_pos == location:
			return

	var is_new: = false
	var location_node: = map_note_scene.instance()

	if data.empty():
		is_new = true
		data = DEFAULT_LOCATION_DATA.duplicate()
		data.pos = Globals.convert_to_grid(get_global_mouse_position())

	var icon: = "DEFAULT"
	if "icon" in data and data.icon:
		icon = data.icon


	if "pos" in data:
		if data.pos is String:
			pos = str2var(data.pos)
		elif data.pos is Vector2:
			pos = data.pos

	location_node.location = GameData.location_library.add(data)
	grid.add_child(location_node)
	location_node.global_position = grid.map_to_world(pos)


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

func load_map(map:Dictionary)->void:
	for child in notes.get_children():
		child.queue_free()

	if map and "image" in map and map.image:
		var texture = load(map.image)
		map_texture.texture = texture
	else:
		var texture = Globals.DEFAULT_MAP_IMAGE
		map_texture.texture = texture
	if "locations" in map:
		for pos in map.locations:
			add_pin(map.locations[pos].pos, map.locations[pos])


func _on_location_created_network(data:Dictionary)-> void:
	if not "pos" in data:
		print("error in network data, cant create a map note without a position")
		return
	add_pin(data.pos, data)


func _on_location_removed_network(data:Dictionary)-> void:
	if not "pos" in data:
		print("error in network data, cant create a map note without a position")
		return
	else:
		remove_pin(data.pos)


func _on_network_map_note_deleted(note_pos:Vector2)-> void:
	remove_pin(note_pos)


func _on_map_scroll_speed_changed(new_scroll_speed: float) -> void:
	scroll_speed = new_scroll_speed


func _on_map_loaded(map:Dictionary)->void:
	load_map(map)


func _on_screen_changed(screen:String)-> void:
	if screen == "main":
		set_process(true)
	else:
		set_process(false)


func _on_popup(_data, _overlay)-> void:
	set_process(false)


func _on_all_popups_finished()-> void:
	set_process(true)


func _on_match_joined(server_match:NakamaRTAPI.Match)-> void:
	add_new_player_cursors(ServerConnection.presences)


func _on_presences_changed(presences)-> void:
	add_new_player_cursors(presences)


func add_new_player_cursors(presences)-> void:
	for presence in presences:
		var new_player = player_cursor_scene.instance()
		new_player.setup_puppet(presence)
		grid.add_child(new_player)


func _on_map_pin_dropped(pin_node:Node)-> void:
	if not "pos" in pin_node or not "data" in pin_node:
		return
	add_pin(pin_node.pos, pin_node.data)


func _on_location_added(location_resource:NetworkedResource)-> void:
	var pos = location_resource.find("pos")
	if pins.has(pos):
		return
	else:
		notes_added.append(location_resource)
		add_pin(pos, location_resource.data)
