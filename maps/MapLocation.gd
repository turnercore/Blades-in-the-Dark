class_name MapNote
extends Area2D

export(PackedScene) var edit_note_popup
export(NodePath) onready var location_name_label = get_node(location_name_label) as Label
export(NodePath) onready var info_text_label = get_node(info_text_label) as Label
onready var map_note_texture:= $MapNoteTexture
onready var anim:= $AnimationPlayer

#Note Data
var tags:= ""
var pos:Vector2
var icon:String= GameData.DEFAULT_MAP_NOTE_ICON setget _set_icon
var shortcut: = false
var location_name:String setget _set_location_name
var info_text:String setget _set_info_text
var description:String setget _set_description

var cursor_hovered: = false
var locked: = false
var is_ready: = false
var enlarged: = false
var shrunk:= true


signal cursor_hovered

onready var icon_texture: = load(icon)

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


func _set_icon(value: String)-> void:
	if not value:
		value = GameData.DEFAULT_MAP_NOTE_ICON
	icon = value
	#add a file exists check
	icon_texture = load(icon) if not icon == "NONE" else null
	if not is_ready: yield(self, "ready")
	map_note_texture.texture = icon_texture


func _on_cursor_free()->void:
	cursor_hovered = false

func _set_description(value: String)-> void:
	self.info_text = value
	description = value


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


func create_popup()-> EditNotePopup:
	var popup:EditNotePopup = edit_note_popup.instance()
	var data: = {
		"tags": tags,
		"pos": global_position,
		"icon": icon,
		"shortcut": shortcut,
		"location_name": location_name,
		"info_text": info_text
	}

	for property in data:
		if property in popup:
			popup.set(property, data[property])
		if property in popup.data:
			popup.data[property] = data[property]

	return popup


func _on_MapNote_area_entered(area: Area2D) -> void:
	if locked: return

	if area is Cursor and not cursor_hovered:
		cursor_hovered = true
		if not info_text:
			info_text = "Info text missing"

		Tooltip.display_tooltip(location_name, info_text)
#		Events.emit_signal("info_broadcasted", info_text.c_unescape())
		enlarge()


func _on_MapNote_area_exited(area: Area2D) -> void:
	cursor_hovered = false
	if area is Cursor:
		if not locked:
			Tooltip.finish_tooltip()
#			Events.emit_signal("info_broadcasted", "")
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
	location_name_label.text = location_name.c_unescape().capitalize()


func _set_info_text(value: String)-> void:
	info_text = value
	info_text_label.text = info_text.c_unescape()
