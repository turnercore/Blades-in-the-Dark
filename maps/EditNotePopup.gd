class_name EditNotePopup
extends WindowDialog

var location_name: = "" setget _set_loc_name
var info_text: = "" setget _set_info_text


func _set_info_text(value:String)-> void:
	info_text = value
	$VBoxContainer/TextEdit.text = value

func _set_loc_name(value:String)-> void:
	location_name = value
	$VBoxContainer/Label.text = value
