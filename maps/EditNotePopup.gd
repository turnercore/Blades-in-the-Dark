class_name EditNotePopup
extends WindowDialog


var pos: = Vector2.ZERO
var location_name: = "" setget _set_loc_name
var description: = "" setget _set_description
var icon: = "" setget _set_icon
var shortcut: = false
var tags: = ""
var data:= {}

onready var note_info_label: = $VBoxContainer/note_info
onready var location_name_label: = $VBoxContainer/HBoxContainer2/location_name
onready var icon_option: = $VBoxContainer/HBoxContainer2/IconOptionButton
onready var shortcut_button: = $VBoxContainer/HBoxContainer/shortcut_button

var is_ready: = false
signal finished_ready
var is_deleting: = false

func _ready() -> void:
	if shortcut:
		shortcut_button.pressed = true
	update_data()
	is_ready = true
	emit_signal("finished_ready")




func update_data()-> void:
	data= {
	"pos": Globals.convert_to_grid(pos),
	"location_name": location_name,
	"description": description,
	"icon": icon,
	"shortcut": shortcut,
	"tags": tags
	}




func save_and_close()-> void:
	if is_deleting: return
	update_data()
	Events.emit_signal("popup_finished")
	Events.emit_signal("map_note_updated", data)
	queue_free()


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


func _set_description(value:String)-> void:
	description = value.c_escape()
	if not is_ready: yield(self, "finished_ready")
	note_info_label.text = value.c_unescape()



func _set_icon(value:String)-> void:
	icon = value
	set_icon_button(value)


func _set_loc_name(value:String)-> void:
	location_name = value.c_escape()
	data.location_name = location_name
	if not is_ready: yield(self, "finished_ready")
	location_name_label.text = value.c_unescape()


func _on_DeleteButton_pressed() -> void:
	is_deleting = true
	Events.emit_signal("map_note_removed", pos)
	Events.emit_signal("popup_finished")
	queue_free()


func _on_location_name_text_changed(new_text: String) -> void:
	location_name = new_text.c_escape()


func _on_note_description_changed() -> void:
	description = $VBoxContainer/note_info.text.c_escape()


func _on_SaveButton_pressed() -> void:
	save_and_close()


func _on_EditNotePopup_modal_closed() -> void:
	save_and_close()


func _on_IconOptionButton_item_selected(index: int) -> void:
	lookup_icon(icon_option.get_item_id(index))


func _on_shortcut_button_toggled(button_pressed: bool) -> void:
	shortcut = button_pressed
	data.shortcut = shortcut


func _on_EditNotePopup_popup_hide() -> void:
	save_and_close()
