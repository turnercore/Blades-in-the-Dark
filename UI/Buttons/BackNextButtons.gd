class_name BackNextButtons
extends HBoxContainer

export (String) var page_name: = ""
export (bool) var finished: = false setget _set_finished
export (bool) var require_data_for_next: = true setget _set_require_data_for_next
export (bool) var back_button_enabled: = true setget _set_back_button_enabled
export (Array, NodePath) var input_nodes

onready var next_button: = $NextButton
onready var back_button: = $BackButton

var next_disabled: = false
var is_ready: = false
var nodes_with_data: = []

signal finished
signal next
signal back
signal finished_page(page_name)


func _ready() -> void:
	if input_nodes.empty():
		require_data_for_next = false

	next_button.text = "Finished" if finished else "Next"
	next_button.disabled = require_data_for_next
	back_button.visible = back_button_enabled

	for nodepath in input_nodes:
		var node:Node = get_node(nodepath)
		var node_had_data: = false
#		children_with_data.append(node)
		if node.has_signal("item_selected"):
			if not node.is_connected("item_selected", self, "_on_data_entered"):
				node.connect("item_selected", self, "_on_data_entered", [node])
			node_had_data = true
		elif node.has_signal("text_entered"):
			if not node.is_connected("text_entered", self, "_on_data_entered"):
				node.connect("text_entered", self, "_on_data_entered", [node])
			node_had_data = true
		elif node.has_signal("toggled"):
			if not node.is_connected("toggled", self, "_on_data_entered"):
				node.connect("toggled", self, "_on_data_entered", [node])
			node_had_data = true
		if node_had_data:
			nodes_with_data.append(node)

	if finished and not back_button_enabled:
		next_button.size_flags_horizontal = Container.SIZE_SHRINK_CENTER + Container.SIZE_EXPAND

	is_ready = true



func _on_NextButton_pressed() -> void:
	if next_button.disabled: return
	if not finished: emit_signal("next")
	else: emit_signal("finished")
	if page_name != "":
		emit_signal("finished_page", page_name)


func _on_BackButton_pressed() -> void:
	if back_button.disabled: return
	if back_button_enabled: emit_signal("back")


func _set_finished(value:bool)-> void:
	finished = value
	if not is_ready: return
	next_button.text = "Finished" if finished else "Next"


func _set_require_data_for_next(value:bool)-> void:
	require_data_for_next = value
	if not is_ready: return
	next_button.disabled = true if require_data_for_next else false


func _set_back_button_enabled(value:bool)-> void:
	back_button_enabled = value
	if not is_ready: return
	back_button.visible = back_button_enabled

func _on_data_entered(_value, node:Node)-> void:
	if not nodes_with_data.has(node):
		return

	if node.has_signal("item_selected"):
		if node.is_connected("item_selected", self, "_on_data_entered"):
			node.disconnect("item_selected", self, "_on_data_entered")
	elif node.has_signal("text_entered"):
		if node.is_connected("text_entered", self, "_on_data_entered"):
			node.disconnect("text_entered", self, "_on_data_entered")
	elif node.has_signal("toggled"):
		if node.is_connected("toggled", self, "_on_data_entered"):
			node.disconnect("toggled", self, "_on_data_entered")

	nodes_with_data.erase(node)

	if nodes_with_data.empty():
		next_button.disabled = false
