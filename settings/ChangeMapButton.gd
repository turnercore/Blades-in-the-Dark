extends Button

export (NodePath) onready var file_dialog = get_node(file_dialog) as FileDialog
export (NodePath) onready var map_name_line_edit = get_node(map_name_line_edit) as LineEdit
export (NodePath) onready var confirm_button = get_node(confirm_button) as Button
export (NodePath) onready var map_name_chooser = get_node(map_name_chooser) as Popup
var map_name: = ""
var image: = ""

func _on_ChangeMapButton_pressed() -> void:
	file_dialog.popup()


func _on_FileDialog_file_selected(path: String) -> void:
	#Should probably validate this is an image TODO
	image = path
	map_name_chooser.popup()


func _on_MapNameConfirm_pressed() -> void:
	map_name_chooser.hide()
	map_name_line_edit.text = ""
	confirm_button.disabled = true
	map_name = ""
	image = ""


func _on_MapNameLineEdit_text_changed(new_text: String) -> void:
	map_name = new_text.c_escape().strip_escapes().strip_edges()
	if confirm_button.disabled: confirm_button.disabled = false
