class_name MapNote
extends Area2D

export(PackedScene) var edit_note_popup
onready var location_name_label: = $MapNoteTexture/location_name
onready var description_label: = $MapNoteTexture/description
onready var map_note_texture:= $MapNoteTexture
onready var anim:= $AnimationPlayer

#Note Data
var tags:= []
var pos:Vector2
var icon:String
var location_name:String setget _set_location_name
var description:String setget _set_description

var cursor_hovered: = false
var locked: = false
var is_ready: = false
var enlarged: = false
var shrunk:= true
var is_not_setup: = true

signal cursor_hovered

onready var icon_texture: = preload("res://Shared/Art/Icons/MapNoteIconTex.tres")

func _ready() -> void:
	if not icon: self.icon = GameData.DEFAULT_MAP_NOTE_ICON
	else: map_note_texture.texture = icon_texture
	connect("area_entered", self, "_on_MapNote_area_entered")
	connect("area_exited", self, "_on_MapNote_area_exited")
	Events.connect("map_note_clicked", self, "_on_clicked")
	Events.connect("popup", self, "_on_popup")
	if not Events.is_connected("popup_finished" ,self, "_on_popup_finished"):
		Events.connect("popup_finished" ,self, "_on_popup_finished")
	Events.connect("cursor_free", self, "_on_cursor_free")
#	shrink()
	is_ready = true
	is_not_setup = false

func setup_from_data(data:Dictionary)-> void:
	for property in data:
		if property in self:
			set(property, data[property])
	is_not_setup = false

func package()->Dictionary:
	var data: = {
		"tags": tags,
		"pos": pos,
		"icon": icon,
		"location_name": location_name,
		"description": description
	}
	return data

func _set_icon(value: String)-> void:
	if not value:
		value = GameData.DEFAULT_MAP_NOTE_ICON
	icon = value
	if is_not_setup: return
	#add a file exists check
	icon_texture = load(icon) if not icon == "NONE" else null
	if not is_ready: yield(self, "ready")
	map_note_texture.texture = icon_texture


func _on_cursor_free()->void:
	cursor_hovered = false


func _on_clicked(note)->void:
	if locked: return

	if note == self:
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
	popup.map_location = self
	return popup


func _on_MapNote_area_entered(area: Area2D) -> void:
	if locked: return

	if area is Cursor and not cursor_hovered:
		cursor_hovered = true
		if not description:
			description = "Info text missing"

		Tooltip.display_tooltip(location_name, description)
		enlarge()


func _on_MapNote_area_exited(area: Area2D) -> void:
	cursor_hovered = false
	if area is Cursor:
		if "is_remote" in area and not area.is_remote and not locked:
			Tooltip.finish_tooltip()
			shrink()
			Events.emit_signal("cursor_free")


func _on_popup_finished()-> void:
	if locked: self.locked = false


func _set_locked(value: bool)-> void:
	locked = value

	if not cursor_hovered:
		shrink()


func _on_popup(_data, _overlay)->void:
	locked = true


func _set_location_name(value:String)-> void:
	location_name = value.c_escape()
	if location_name_label:
		location_name_label.text = location_name.c_unescape().capitalize()


func _set_description(value: String)-> void:
	description = value
	if description_label:
		description_label.text = description.c_unescape()
