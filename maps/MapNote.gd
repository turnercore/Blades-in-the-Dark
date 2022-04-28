class_name MapNote
extends Control

export(PackedScene) var edit_note_popup
onready var location_name_label: = $MapNote/MapNoteTexture/location_name
onready var description_label: = $MapNote/MapNoteTexture/description
onready var map_note_texture:= $MapNote/MapNoteTexture
onready var anim:= $MapNote/AnimationPlayer
onready var map_note_area: = $MapNote

var location:NetworkedResource
#Note Data

var cursor_hovered: = false
var locked: = false
var enlarged: = false
var shrunk:= true

var is_ready: = false
var is_not_setup: = true

var pos:Vector2
var global_position:Vector2 setget _set_global_position

signal cursor_hovered

onready var default_icon_texture: = preload("res://Shared/Art/Icons/MapNoteIconTex.tres")
var icon_texture:Texture

func _ready() -> void:
	if not icon_texture: icon_texture = default_icon_texture
	map_note_texture.texture = icon_texture
	connect_to_events()
	map_note_area.global_position = global_position
	is_ready = true
	is_not_setup = false
	name = location.get_property("location_name")
	update_location_name(location.get_property("location_name"))
	update_description(location.get_property("description"))


func connect_to_events()-> void:
	location.connect("property_changed", self, "_on_location_property_changed")
	location.connect("deleted", self, "_on_location_deleted")
	map_note_area.connect("area_entered", self, "_on_MapNote_area_entered")
	map_note_area.connect("area_exited", self, "_on_MapNote_area_exited")
	Events.connect("map_note_clicked", self, "_on_clicked")
	Events.connect("popup", self, "_on_popup")
	if not Events.is_connected("popup_finished" ,self, "_on_popup_finished"):
		Events.connect("all_popups_finished" ,self, "_on_all_popups_finished")
	Events.connect("cursor_free", self, "_on_cursor_free")


func _on_location_property_changed(property, value)-> void:
	match property:
		"location_name":
			update_location_name(value)
		"name":
			name = value
			update_location_name(value)
		"description":
			update_description(value)
		"icon":
			update_icon(value)

func _on_location_deleted()-> void:
	queue_free()


func update_location_name(value:String)-> void:
	if location_name_label:
		location_name_label.text = value.c_unescape().capitalize()


func update_description(value: String)-> void:
	if description_label:
		description_label.text = value.c_unescape()


func update_icon(value: String)-> void:
	if not value:
		value = GameData.DEFAULT_MAP_NOTE_ICON
	#add a file exists check
	icon_texture = load(value) if value and not value == "NONE" else null
	map_note_texture.texture = icon_texture


func _on_cursor_free()->void:
	cursor_hovered = false


func _on_clicked(note)->void:
	if locked: return
	if note == map_note_area:
		Events.popup(create_popup())


func enlarge()-> void:
	if not locked and not enlarged:
		anim.play("enlarge")
		enlarged = true
		shrunk = false


func shrink()-> void:
	if not locked and not shrunk:
		anim.play("shrink")
		shrunk = true
		enlarged = false


func create_popup() -> WindowDialog:
	var popup = edit_note_popup.instance()
	popup.location = location
	return popup


func _on_MapNote_area_entered(area: Area2D) -> void:
	if locked: return
	if area is Cursor and not cursor_hovered:
		cursor_hovered = true
		Tooltip.display_tooltip(location.get_property("location_name"), location.get_property("description"))
		enlarge()


func _on_MapNote_area_exited(area: Area2D) -> void:
	cursor_hovered = false
	if area is Cursor:
		if "is_remote" in area and not area.is_remote and not locked:
			Tooltip.finish_tooltip()
			shrink()
			Events.emit_signal("cursor_free")


func _on_all_popups_finished()-> void:
	if locked: self.locked = false


func _set_locked(value: bool)-> void:
	locked = value
	if not cursor_hovered:
		shrink()


func _on_popup(_data, _overlay)->void:
	locked = true


func _set_global_position(value)-> void:
	var pos:Vector2
	if value is String:
		pos = Globals.str_to_vec2(value)
	if value is Vector2:
		pos = value
		global_position = pos
		if map_note_area:
			map_note_area.global_position = pos
