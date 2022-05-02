extends HBoxContainer

const PLAYBOOK_FIELD_TEMPLATE: = "items.%s"

var resource:NetworkedResource setget _set_resource

onready var load_node: = $load
onready var item_name_node: = $item_name
onready var description_node: = $description
onready var using_node: = $using

var item: String = ""
var description: String = ""
var carry_load: int = 0
var using: bool = false setget _set_using


signal load_updated(amount)


func _ready()-> void:
	if resource: setup(resource)


func setup(new_playbook:NetworkedResource)-> void:
	for child in load_node.get_children(): child.queue_free()

	var field_template: = PLAYBOOK_FIELD_TEMPLATE % item.to_lower().replace(" ", "_")
	item_name_node.playbook_field = field_template + ".item"
	description_node.playbook_field = field_template + ".description"
	using_node.playbook_field = field_template + ".using"

	for i in carry_load:
		var check_box: = CheckBox.new()
		check_box.pressed = using
		check_box.connect("toggled", self, "_on_load_toggled")
		load_node.add_child(check_box)

	Globals.propagate_set_property_recursive(self, "resource", new_playbook)


func _set_resource(new_playbook:NetworkedResource)-> void:
	resource = new_playbook
	setup(new_playbook)


func _set_item(value:String)-> void:
	item = value.to_lower().replace(" ", "_")
	setup(resource)


func _set_using(value:bool)->void:
	using = value
	using_node.pressed = value
	using_node.emit_signal("toggled")


func _on_load_toggled(button_pressed: bool)-> void:
	self.using = button_pressed

	for load_checkbox in load_node.get_children():
		load_checkbox.pressed = button_pressed
	if button_pressed: emit_signal("load_updated", carry_load)
	elif not button_pressed: emit_signal("load_updated", -carry_load)
