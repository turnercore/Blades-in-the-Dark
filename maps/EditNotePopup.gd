class_name EditNotePopup
extends WindowDialog

var location:NetworkedResource
var pos: = Vector2.ZERO setget _set_pos
onready var location_name:String = location.get_property("location_name") setget _set_loc_name
onready var description:String = location.get_property("description") setget _set_description
onready var icon = location.get_property("icon") setget _set_icon

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
	pos = location.get_property("pos")
	if GameData.map_shortcuts.has(pos):
		shortcut_button.pressed = true
	emit_signal("finished_ready")


func save_and_close()-> void:
	if is_deleting: return
	Events.emit_signal("popup_finished")
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
	description = value
	if not is_ready: yield(self, "finished_ready")
	location.update("description", description)
	if not is_ready: yield(self, "finished_ready")
	if description_text_edit.text != value:
		description_text_edit.text = value


func _set_icon(value:String)-> void:
	icon = value
	set_icon_button(value)
	location.update("icon", value)


func _set_pos(value:Vector2)-> void:
	pos = value
	location.update("pos", value)


func _set_loc_name(value:String)-> void:
	value = value.strip_escapes().strip_edges()
	location_name = value
	location.update("location_name", location_name)
	if not is_ready: yield(self, "finished_ready")
	if location_name_label.text != value:
		location_name_label.text = value


func _on_DeleteButton_pressed() -> void:
	is_deleting = true
	Events.emit_signal("location_removed", pos)
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
		GameData.add_map_shortcut(location.get_vec2("pos"))
	else:
		GameData.remove_map_shortcut(location.get_vec2("pos"))


func _on_EditNotePopup_popup_hide() -> void:
	save_and_close()


func _on_description_text_changed() -> void:
	self.description = description_text_edit.text
