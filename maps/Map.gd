class_name Map
extends Node2D

const map_note_scene: = preload("res://maps/MapNote.tscn")

export (float) var scroll_speed:float = 500
export (NodePath) onready var tween = get_node(tween) as Tween
export (NodePath) onready var cursor = get_node(cursor) as Cursor
export (NodePath) onready var cursor_sprite = get_node(cursor_sprite) as Sprite
export (NodePath) onready var notes = get_node(notes) as Node2D
export (NodePath) onready var camera = get_node(camera) as Camera2D
export (NodePath) onready var map_texture = get_node(map_texture) as TextureRect

var zoom_level: float
var unfocused: = false


func _ready() -> void:
	GameData.connect("map_loaded", self, "_on_map_loaded")
	Events.connect("map_scroll_speed_changed", self, "_on_map_scroll_speed_changed")
	Events.connect("main_screen_changed", self, "_on_screen_changed")
	Events.connect("chat_selected", self, "_on_chat_selected")
	Events.connect("chat_deselected", self, "_on_chat_deselected")
	zoom_level = camera.zoom.x


func _process(delta: float) -> void:
	if unfocused: return
	if Input.is_action_just_pressed("right_click"):
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


func add_note(pos:=Vector2.ZERO, note_data:={})->void:
	var map_note = map_note_scene.instance()
	if pos == Vector2.ZERO and note_data.empty():
		print("adding a new note")
		pos = get_global_mouse_position()
		#Need to do the a popup and yeild for it to finish or somehting here to get the rest of the data
		note_data["info_text"] = "Hello world"
		note_data["location"] = pos
		GameData.add_map_note(pos, note_data)
	else:
		print("adding a pre-existing note")
		#Need to do setup on the map note to load it with the data


	for property in note_data:
		if property in map_note:
			map_note.set(property, note_data[property])

	map_note.global_position = pos
	notes.add_child(map_note)


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

	if map and "image" in map:
		var texture = load(map.image)
		map_texture.texture = texture
	else:
		var texture = load(GameData.DEFAULT_MAP_IMAGE)
		map_texture.texture = texture

	if map and "notes" in map:
		for pos in map.notes:
			print('loading a note at this pos:')
			print(pos)
			add_note(pos, map.notes[pos])


func _on_map_scroll_speed_changed(new_scroll_speed: float) -> void:
	scroll_speed = new_scroll_speed


func _on_map_loaded(map:Dictionary)->void:
	print("MAP LOADED")
	print("___________")
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

