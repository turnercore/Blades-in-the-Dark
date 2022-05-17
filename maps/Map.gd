class_name Map
extends Node2D

export (float) var scroll_speed:float = 500
export (NodePath) onready var tween = get_node(tween) as Tween
export (NodePath) onready var cursor = get_node(cursor) as Cursor
export (NodePath) onready var pins = get_node(pins) as Node2D
export (NodePath) onready var camera = get_node(camera) as Camera2D
export (NodePath) onready var map_texture = get_node(map_texture) as TextureRect
export(NodePath) onready var players = get_node(players) as Node2D
export (NodePath) onready var drawing_canvas = get_node(drawing_canvas) as Node2D
export (NodePath) onready var regions = get_node(regions) as MapRegions
export (NodePath) onready var pings = get_node(pings) as Pings
export (PackedScene) var player_cursor_scene
export (PackedScene) var ping_scene

var zoom_level: float
var unfocused: = false
onready var player_cursors: = [cursor]

var has_clicked: = false
var alt_held_down: = false

#TODO: move Ping code into Pings Node

func _ready() -> void:
	connect_to_events()
	if GameData.map:
		load_map(GameData.map)
	else:
		print("waiting on map to load")
		yield(GameData, "map_loaded")

	if ServerConnection.is_connected_to_server:
		add_new_player_cursors(ServerConnection.presences)

	zoom_level = camera.zoom.x


func connect_to_events()-> void:
	GameData.connect("map_loaded", self, "_on_map_loaded")
	Events.connect("map_scroll_speed_changed", self, "_on_map_scroll_speed_changed")
	Events.connect("popup", self, "_on_popup")
	Events.connect("all_popups_finished", self, "_on_all_popups_finished")
	Events.connect("map_changed", self, "_on_map_changed")
	ServerConnection.connect("match_joined", self, "_on_match_joined")
	ServerConnection.connect("presences_changed", self, "_on_presences_changed")
	NetworkTraffic.connect("player_pinged", self, "ping")


func _process(delta: float) -> void:
	if unfocused: return
	if Input.is_action_just_pressed("alt"):
		alt_held_down = true
	if Input.is_action_just_released("alt"):
		alt_held_down = false
	if Input.is_action_just_pressed("left_click") and alt_held_down:
		drawing_canvas.point = get_global_mouse_position()
	if Input.is_action_just_pressed("left_click") and not has_clicked:
		has_clicked = true
		yield(get_tree().create_timer(0.25), "timeout")
		if has_clicked: has_clicked = false
	if Input.is_action_just_pressed("left_click") and has_clicked:
		ping()
		has_clicked = false
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


func ping(ping_data:Dictionary = {})-> void:
	var ping:Node2D = ping_scene.instance()
	if not ping_data.empty():
		ping.pos = ping_data.pos
		ping.color = ping_data.color
	else:
		ping.pos = get_global_mouse_position()
		ping.color = GameData.player_color
	pings.add_child(ping)


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

func load_map(map:NetworkedResource)->void:
	var texture = load(map.find("image"))
	map_texture.texture = texture
	pins.reset()
	regions.reset()


func _on_map_scroll_speed_changed(new_scroll_speed: float) -> void:
	scroll_speed = new_scroll_speed


func _on_map_loaded(map:NetworkedResource)->void:
	load_map(map)


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
		players.add_child(new_player)


func _on_map_changed()-> void:
	load_map(GameData.map)
