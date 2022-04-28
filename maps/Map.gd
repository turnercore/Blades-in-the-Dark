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
var creating_note: = false
onready var player_cursors: = [cursor]
var notes_added: = []

func _ready() -> void:
	Globals.grid = grid

	GameData.connect("map_loaded", self, "_on_map_loaded")
	Events.connect("map_scroll_speed_changed", self, "_on_map_scroll_speed_changed")
	Events.connect("chat_selected", self, "_on_chat_selected")
	Events.connect("chat_deselected", self, "_on_chat_deselected")
	Events.connect("popup", self, "_on_popup")
	Events.connect("all_popups_finished", self, "_on_all_popups_finished")
	ServerConnection.connect("match_joined", self, "_on_match_joined")
	ServerConnection.connect("presences_changed", self, "_on_presences_changed")
	NetworkTraffic.connect("gamedata_location_created", self, "_on_location_created_network")
	NetworkTraffic.connect("gamedata_location_updated", self, "_on_network_map_note_updated")
	NetworkTraffic.connect("gamedata_location_removed", self, "_on_network_map_note_removed")
	load_map()

	if ServerConnection.is_connected_to_server:
		add_new_player_cursors(ServerConnection.presences)

	zoom_level = camera.zoom.x



func _process(delta: float) -> void:
	if unfocused: return
	if Input.is_action_pressed("display_map_coords"):
		var info_string:= "Map Grid Coords: \n" + str(Globals.convert_to_grid(get_global_mouse_position()))
		Events.emit_signal("info_broadcasted", info_string)
	if Input.is_action_just_pressed("right_click") and not creating_note:
		creating_note = true
		var initial_note_data: = DEFAULT_LOCATION_DATA.duplicate()
		initial_note_data.pos = Globals.convert_to_grid(get_global_mouse_position())
		add_location(initial_note_data.pos, initial_note_data)
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


func add_location(pos:=Vector2.ZERO, data:Dictionary = DEFAULT_LOCATION_DATA.duplicate(), local:bool = true)->void:
	var location: = map_note_scene.instance()
	grid.add_child(location)
	location.import(data)
	location.global_position = grid.map_to_world(pos)
	if local:
		Events.emit_signal("map_note_created", location)

	creating_note = false


func delete_note(pos:Vector2)-> void:
	Events.emit_signal("map_note_removed", pos)


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


func load_map()->void:
	var map:Dictionary = GameData.map if not GameData.map.empty() else GameData.save_game.maps.front()

	for child in notes.get_children():
		child.queue_free()

	if map and "image" in map and map.image:
		var texture = load(map.image)
		map_texture.texture = texture
	else:
		var texture = Globals.DEFAULT_MAP_IMAGE
		map_texture.texture = texture

	for pos in map.notes:
		add_location(pos, map.notes[pos])


func _on_location_created_network(data:Dictionary)-> void:
	if not "pos" in data:
		print("error in network data, cant create a map note without a position")
		return
	add_location(data.pos, data, false)



func _on_network_map_note_updated(note_data:Dictionary)-> void:
	pass


func _on_network_map_note_deleted(note_pos:Vector2)-> void:
	pass


func _on_map_scroll_speed_changed(new_scroll_speed: float) -> void:
	scroll_speed = new_scroll_speed


func _on_map_loaded()->void:
	load_map()


func _on_chat_selected()->void:
	set_process(false)


func _on_chat_deselected()-> void:
	set_process(true)


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
