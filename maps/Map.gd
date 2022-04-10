class_name Map
extends Control

export (float) var scroll_speed:float = 500
onready var tween: = $Tween
var camera: Camera2D
var zoom_level: float
onready var cursor: = $Cursor
onready var cursor_sprite: = $Cursor/Sprite
onready var notes: = $Notes
var unfocused: = false


func _ready() -> void:
	GameData.connect("map_loaded", self, "_on_map_loaded")
	set_process(false)


func setup(main_camera: Camera2D)->void:
	print(main_camera)
	camera = main_camera
	print(camera)
	zoom_level = camera.zoom.x
	Events.connect("map_scroll_speed_changed", self, "_on_map_scroll_speed_changed")
	Events.connect("main_screen_changed", self, "_on_screen_changed")
	Events.connect("chat_selected", self, "_on_chat_selected")
	Events.connect("chat_deselected", self, "_on_chat_deselected")
	set_process(true)


func _on_chat_selected()->void:
	set_process(false)


func _on_chat_deselected()-> void:
	set_process(true)


func _on_screen_changed(screen:String)-> void:
	if screen == "main":
		set_process(true)
	else:
		set_process(false)


func _process(delta: float) -> void:
	if unfocused: return
	if Input.is_action_just_pressed("right_click"):
		add_note()
	if Input.is_action_just_pressed("left_click"):
		print("left click on map")
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
	var map_note = load("res://maps/MapNote.tscn").instance()
	if pos == Vector2.ZERO and note_data.empty():
		print("adding a new note")
		pos = get_global_mouse_position()
		#Need to do the a popup and yeild for it to finish or somehting here to get the rest of the data
		note_data["text"] = "Hello world"
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


func _on_map_scroll_speed_changed(new_scroll_speed: float) -> void:
	scroll_speed = new_scroll_speed

func _on_map_loaded(map:Dictionary)->void:
	if map and "notes" in map:
		for pos in map.notes:
			add_note(pos, map.notes[pos])
