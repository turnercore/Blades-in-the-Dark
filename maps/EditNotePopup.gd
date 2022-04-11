class_name EditNotePopup
extends WindowDialog


var pos: = Vector2.ZERO setget _set_pos
var location_name: = "" setget _set_loc_name
var info_text: = "" setget _set_info_text
var icon: = "" setget _set_icon
var shortcut: = false setget _set_shortcut

export (NodePath) onready var note_info_label = get_node(note_info_label)
export (NodePath) onready var location_name_label = get_node(location_name_label)
export (NodePath) onready var icon_option = get_node(icon_option) as OptionButton


var data:= {
	"pos": pos,
	"location_name": location_name,
	"info_text": info_text,
	"icon": icon,
	"shortcut": shortcut
}


func save_and_close()-> void:
	queue_free()
	Events.emit_signal("popup_finished")
	Events.emit_signal("map_note_updated", data)


func lookup_icon(index:int)->String:
	var icon:= ""
	match index:
		0:
			icon = "old_map_icon"
		_:
			icon = "not found"

	return icon


func set_icon_button(icon: String)-> void:
	pass


func _set_pos(value:Vector2)-> void:
	pos = value
	data.pos = pos


func _set_info_text(value:String)-> void:
	info_text = value.c_escape()
	data.info_text = info_text
	note_info_label.text = value.c_unescape()


func _set_shortcut(value:bool)-> void:
	shortcut = value
	data.shortcut = shortcut



func _set_icon(value:String)-> void:
	icon = value
	data.icon = icon
	set_icon_button(value)


func _set_loc_name(value:String)-> void:
	location_name = value.c_escape()
	data.location_name = location_name
	location_name_label.text = value.c_unescape()


func _on_DeleteButton_pressed() -> void:
	Events.emit_signal("map_note_removed", pos)
	Events.emit_signal("popup_finished")
	queue_free()


func _on_location_name_text_changed(new_text: String) -> void:
	location_name = new_text.c_escape()
	data.location_name = location_name


func _on_note_info_text_changed() -> void:
	info_text = $VBoxContainer/note_info.text.c_escape()
	data.info_text = info_text


func _on_SaveButton_pressed() -> void:
	save_and_close()


func _on_EditNotePopup_modal_closed() -> void:
	save_and_close()


func _on_IconOptionButton_item_selected(index: int) -> void:
	lookup_icon(icon_option.get_item_id(index))
