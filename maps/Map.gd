class_name Map
extends Node2D

const map_note_scene: = preload("res://maps/MapNote.tscn")

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
	load_map(GameData.map)
	Events.connect("map_scroll_speed_changed", self, "_on_map_scroll_speed_changed")
	Events.connect("chat_selected", self, "_on_chat_selected")
	Events.connect("chat_deselected", self, "_on_chat_deselected")
	Events.connect("popup", self, "_on_popup")
	Events.connect("popup_finished", self, "_on_popup_finished")
	ServerConnection.connect("match_joined", self, "_on_match_joined")
	ServerConnection.connect("presences_changed", self, "_on_presences_changed")
	NetworkTraffic.connect("gamedata_location_created", self, "_on_map_note_added")
	NetworkTraffic.connect("gamedata_location_updated", self, "_on_map_note_changed")
	NetworkTraffic.connect("gamedata_location_removed", self, "_on_map_note_removed")

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
		add_note()
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


func add_note(pos:=Vector2.ZERO, note_data:={}, local:bool = true)->void:
	if pos == Vector2.ZERO and note_data.empty():
		note_data = GameData.DEFAULT_NOTE.duplicate()
		pos = Globals.convert_to_grid(get_global_mouse_position())
		note_data.pos = pos
		if pos in GameData.map.notes:
			return

	var map_note = map_note_scene.instance()
	notes.add_child(map_note)
	notes_added.append(map_note)

	for property in note_data:
		if property in map_note:
			map_note.set(property, note_data[property])

	map_note.global_position = grid.map_to_world(pos)
	if local: Events.emit_signal("map_note_created", note_data)
	creating_note = false

func delete_note(pos:Vector2)-> void:
	for note in notes_added:
		if note.pos == pos:
			note.queue_free()

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


	if map and "notes" in map:
		for pos in map.notes:
			add_note(pos, map.notes[pos])
	if map and "srd_notes" in map:
		for pos in map.srd_notes:
			var vec_pos:Vector2
			if pos is String:
				vec_pos = Globals.str_to_vec2(pos)
			else:
				vec_pos = pos
			add_note(vec_pos, map.srd_notes[pos])


func _on_map_note_added(note_data:Dictionary)-> void:
	var pos:Vector2
	if not "pos" in note_data:
		return

	if note_data.pos is String:
		pos = Globals.str_to_vec2(note_data.pos)
	elif note_data.pos is Vector2:
		pos = note_data.pos

	add_note(pos, note_data, false)


func _on_map_note_changed(note_data:Dictionary)-> void:
	pass


func _on_map_note_removed(note_pos:Vector2)-> void:
	delete_note(note_pos)



func _on_map_scroll_speed_changed(new_scroll_speed: float) -> void:
	scroll_speed = new_scroll_speed


func _on_map_loaded(map:Dictionary)->void:
	load_map(map)


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


func _on_popup_finished()-> void:
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
