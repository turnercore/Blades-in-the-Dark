class_name MapNote
extends SyncNode

export(PackedScene) var edit_note_popup
onready var location_name_label: = $MapNote/MapNoteTexture/location_name
onready var description_label: = $MapNote/MapNoteTexture/description
onready var map_note_texture:= $MapNote/MapNoteTexture
onready var anim:= $MapNote/AnimationPlayer
onready var map_note_area: = $MapNote

#Note Data
var tags:= []
var pos:Vector2
var icon:String
var location_name:String setget _set_location_name
var description:String setget _set_description
var id:String setget _no_set, _get_id

var cursor_hovered: = false
var locked: = false
var is_ready: = false
var enlarged: = false
var shrunk:= true
var is_not_setup: = true

var global_position:Vector2 setget _set_global_position

signal cursor_hovered

onready var icon_texture: = preload("res://Shared/Art/Icons/MapNoteIconTex.tres")

func _init()-> void:
	export_properties = [
		"tags",
		"pos",
		"icon",
		"location_name",
		"description"
	]

func _ready() -> void:
	if not icon: self.icon = GameData.DEFAULT_MAP_NOTE_ICON
	else: map_note_texture.texture = icon_texture
	connect_to_events()
	map_note_area.global_position = global_position
	is_ready = true
	is_not_setup = false

func connect_to_events()-> void:
	map_note_area.connect("area_entered", self, "_on_MapNote_area_entered")
	map_note_area.connect("area_exited", self, "_on_MapNote_area_exited")
	Events.connect("map_note_clicked", self, "_on_clicked")
	Events.connect("popup", self, "_on_popup")
	if not Events.is_connected("popup_finished" ,self, "_on_popup_finished"):
		Events.connect("all_popups_finished" ,self, "_on_all_popups_finished")
	Events.connect("cursor_free", self, "_on_cursor_free")


func _set_icon(value: String)-> void:
	if not value:
		value = GameData.DEFAULT_MAP_NOTE_ICON
	icon = value
	if is_not_setup: return
	#add a file exists check
	icon_texture = load(icon) if not icon == "NONE" else null
	if not is_ready: yield(self, "ready")
	map_note_texture.texture = icon_texture


#Old function, just keeping around for a bit
func setup_from_data(data:Dictionary)-> void:
	import(data)

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


func _on_all_popups_finished()-> void:
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

func _get_id()-> String:
	if pos:
		return str(pos)
	else:
		return generate_id(5)

func _no_set(_v)->void:
	return


func _set_global_position(value)-> void:
	var pos:Vector2
	if value is String:
		pos = Globals.str_to_vec2(value)
	if value is Vector2:
		pos = value
		global_position = pos
		if map_note_area:
			map_note_area.global_position = pos

#
#func _get_global_position()-> Vector2:
