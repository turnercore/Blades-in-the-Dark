class_name MapNote
extends Area2D

export(PackedScene) var edit_note_popup
onready var anim:= $AnimationPlayer

var tags:= ""
var pos:Vector2
var icon:String= GameData.DEFAULT_MAP_NOTE_ICON setget _set_icon
var shortcut: = false
var location_name:String
var info_text:String

var cursor_hovered: = false
var locked: = false

func _ready() -> void:
	$MapNoteTexture/Label.text = location_name.c_unescape()
	$MapNoteTexture/Label2.text = info_text.c_unescape()
	$MapNoteTexture.texture = load(icon)
	Events.connect("map_note_clicked", self, "_on_clicked")
	Events.connect("cursor_hovered", self, "_on_cursor_hovered")
	Events.connect("cursor_free", self, "_on_cursor_free")
	Events.connect("popup", self, "_on_popup")
	Events.connect("popup_finished" ,self, "_on_popup_finished")
#	Events.connect("cursor_hovered", self, "_on_cursor_hovered")
#	Events.connect("cursor_left", self, "_on_cursor_hovered")
	shrink()


func _set_icon(value: String)-> void:
	icon = value
	$MapNoteTexture.texture = load(icon)


func _on_cursor_hovered()-> void:
	cursor_hovered = true


func _on_cursor_free()->void:
	cursor_hovered = false


func _on_clicked(note)->void:
	if locked: return

	if note == self:
		Events.popup(create_popup())


func enlarge()-> void:
	anim.play("enlarge")


func shrink()-> void:
	anim.play("shrink")


func create_popup()-> EditNotePopup:
	var popup:EditNotePopup = edit_note_popup.instance()
	popup.location_name = location_name
	popup.info_text = info_text
	popup.pos = self.global_position
	return popup


func _on_MapNote_area_entered(area: Area2D) -> void:
	if locked: return

	if area is Cursor and not cursor_hovered:
		Events.emit_signal("cursor_hovered")
		if not info_text:
			return
		Events.emit_signal("info_broadcasted", info_text.c_unescape())
		enlarge()


func _on_MapNote_area_exited(area: Area2D) -> void:
	if locked: return

	if area is Cursor:
		Events.emit_signal("info_broadcasted", "")
		shrink()
		Events.emit_signal("cursor_free")


func _on_popup_finished()-> void:
	shrink()
	cursor_hovered = false
	locked = false

func _on_popup(_data)->void:
	locked = true
