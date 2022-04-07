extends HBoxContainer

var item_name: String = ""
var description: String = ""
var item_load: int = 0
var using: bool = false
onready var load_node: = $load
onready var item_name_node: = $item_name
onready var description_node: = $description

signal load_updated(amount)

func _ready() -> void:
	item_name_node.text = item_name
	description_node.text = description
	for i in item_load:
		var check_box: = CheckBox.new()
		check_box.pressed = using
		check_box.connect("toggled", self, "_on_load_toggled")
		load_node.add_child(check_box)


func _on_load_toggled(button_pressed: bool)-> void:
	for load_checkbox in load_node.get_children():
		load_checkbox.pressed = button_pressed
	if button_pressed: emit_signal("load_updated", item_load)
	elif not button_pressed: emit_signal("load_updated", -item_load)
