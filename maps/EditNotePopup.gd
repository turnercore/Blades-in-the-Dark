class_name EditNotePopup
extends WindowDialog

var map_location:MapNote

var pos: = Vector2.ZERO setget _set_pos
onready var location_name: = map_location.location_name setget _set_loc_name
onready var description: = map_location.description setget _set_description
onready var icon:= map_location.icon setget _set_icon
onready var tags: = map_location.tags setget _set_tags

onready var location_name_label: = $VBoxContainer/HBoxContainer2/location_name
onready var icon_option: = $VBoxContainer/HBoxContainer2/IconOptionButton
onready var shortcut_button: = $VBoxContainer/HBoxContainer/shortcut_button
onready var description_text_edit: = $VBoxContainer/description

var is_ready: = false
signal finished_ready
var is_deleting: = false

func _ready() -> void:
	is_ready = true
	description_text_edit.text = description
	location_name_label.text = location_name
	#TODO Determine if this is a shortcut or not...
	emit_signal("finished_ready")


func save_and_close()-> void:
	if is_deleting: return
	Events.emit_signal("popup_finished")
	Events.emit_signal("map_note_updated", map_location)
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
	if map_location.description != description:
		map_location.description = description
	if not is_ready: yield(self, "finished_ready")
	if description_text_edit.text != value.c_unescape():
		description_text_edit.text = value.c_unescape()


func _set_icon(value:String)-> void:
	icon = value
	set_icon_button(value)
	if map_location.icon != icon:
		map_location.icon = icon


func _set_tags(value:Array)-> void:
	tags = value
	update_tags()


func update_tags()-> void:
	if map_location.tags != tags:
		map_location.tags == tags


func _set_pos(value:Vector2)-> void:
	pos = value
	if map_location.pos != pos:
		map_location.pos = pos


func _set_loc_name(value:String)-> void:
	location_name = value.c_escape()
	if map_location.location_name != location_name:
		map_location.location_name = location_name
	if not is_ready: yield(self, "finished_ready")
	if location_name_label.text != value.c_unescape():
		location_name_label.text = value.c_unescape()


func _on_DeleteButton_pressed() -> void:
	is_deleting = true
	Events.emit_signal("map_note_removed", pos)
	Events.emit_signal("popup_finished")
	queue_free()


func _on_location_name_text_changed(new_text: String) -> void:
	self.location_name = new_text


func _on_SaveButton_pressed() -> void:
	save_and_close()


func _on_EditNotePopup_modal_closed() -> void:
	save_and_close()


func _on_IconOptionButton_item_selected(index: int) -> void:
	lookup_icon(icon_option.get_item_id(index))


func _on_shortcut_button_toggled(button_pressed: bool) -> void:
	if button_pressed:
		GameData.add_map_shortcut(map_location)
	else:
		GameData.remove_map_shortcut(map_location)


func _on_EditNotePopup_popup_hide() -> void:
	save_and_close()


func _on_description_text_changed() -> void:
	self.description = description_text_edit.text.c_escape()
