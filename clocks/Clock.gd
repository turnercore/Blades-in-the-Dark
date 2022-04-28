class_name Clock
extends SyncNode

const RAND_LIMIT: = 1000

enum CLOCK_TYPE {
	ALL,
	OBSTACLE,
	HEALING,
	LONG_TERM_PROJECT,
	LAIR_PROJECT,
	PC_PROJECT,
	FACTION_PROJECT
}

export (Texture) var FOUR_CLOCK_TEXTURE_UNDER
export (Texture) var FOUR_CLOCK_TEXTURE_OVER
export (Texture) var SIX_CLOCK_TEXTURE_UNDER
export (Texture) var SIX_CLOCK_TEXTURE_OVER
export (Texture) var EIGHT_CLOCK_TEXTURE_UNDER
export (Texture) var EIGHT_CLOCK_TEXTURE_OVER
export (Texture) var TWELVE_CLOCK_TEXTURE_UNDER
export (Texture) var TWELVE_CLOCK_TEXTURE_OVER

onready var tween = $Tween
export (NodePath) onready var segments = get_node(segments) as Label
export (NodePath) onready var filled_label = get_node(filled_label) as Label
export (NodePath) onready var clock_texture = get_node(clock_texture) as TextureProgress
export (NodePath) onready var clock_line_edit = get_node(clock_line_edit) as LineEdit
export (NodePath) onready var lock_texture = get_node(lock_texture) as TextureRect
export (NodePath) onready var locked_by_container = get_node(locked_by_container) as Container
export (NodePath) onready var locked_by_clock_label = get_node(locked_by_clock_label) as Label
export (NodePath) onready var locking_clock_label = get_node(locking_clock_label) as Label
export(NodePath) onready var clock_type_option = get_node(clock_type_option) as OptionButton

var locking_clock_picker_scene: = preload("res://clocks/LinkClockPicker.tscn")
var id:String setget ,_get_id
export var clock_name:String = name setget _set_clock_name
export var locked: = false setget _set_locked
var locked_by_clock:String setget _set_locked_by_clock
var locking_clock:String setget _set_locking_clock
export var filled: = 0 setget _set_filled
export var max_value: = 4 setget _set_max_value
export var is_secret: bool = false setget _set_is_secret
var type:int setget _set_type
onready var fill_color:Color = clock_texture.tint_progress setget _set_fill_color

var scale:float = 1 setget _set_scale

var is_setup:= false
var is_saving:= false

signal filled
signal unfilled
signal name_changed(new_name)
signal type_changed(type)

func _init() -> void:
	export_properties = [
		"id",
		"clock_name",
		"filled",
		"max_value",
		"locked",
		"locking_clock",
		"locked_by_clock",
		"type",
		"is_secret",
		"fill_color"
	]

func _ready()->void:
	if not id:
		id = generate_id(5)
	if not locked_by_clock:
		locked_by_container.visible = false

	for clock_type in CLOCK_TYPE:
		var type_str: String = str(clock_type).to_lower().replace("_", " ").capitalize()
		clock_type_option.add_item(type_str)

	self.filled = filled
	self.max_value = max_value
	self.clock_name = clock_name
	self.is_secret = is_secret
	self.locked = locked
	filled_label.text = str(filled)



func setup(new_clock_data:Dictionary)->void:
	import(new_clock_data)
	visible = true
	is_setup = true


func delete()-> void:
	if locking_clock:
		var locking_clock_nodes:NodeReference
		if locking_clock in GameData.clock_nodes:
			GameData.clock_nodes.locking_clock.update_property("locked_by_clock", "")
	if locked_by_clock:
		var locked_by_clock_nodes:NodeReference
		if locked_by_clock in GameData.clock_nodes:
			GameData.clock_nodes.locking_clock.update_property("locking_clock", "")
	Events.emit_clock_removed(self.id)
	delete_connected()


func save_clock()->void:
	Events.emit_clock_updated(self)


func setup_from_data(clock_data:Dictionary)-> void:
	import(clock_data)
	is_setup = true
	visible = true


func lock_clock(clock: Clock)->void:
	self.locking_clock = clock.id
	clock.lock()
	clock.locked_by_clock = self.id
	connect("filled", clock, "unlock")


func unlock()->void:
	if locked:
		self.locked = false


func lock()->void:
	if not locked:
		self.locked = true


func _set_locked(value: bool)->void:
	var locked_check_box: = $CenterContainer/HBoxContainer/EditWidgetContainer/VBoxContainer5/HBoxContainer/LockCheckBox
	locked = value
	save_clock()
	locked_check_box.pressed = value

	if locked:
		clock_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lock_texture.visible = true

	elif not locked:
		clock_texture.mouse_filter = Control.MOUSE_FILTER_STOP
		lock_texture.visible = false


func _get_id()->String:
	if not id:
		id = generate_id(5)
	return id


func _set_filled(value) -> void:
	var new_value: = int(value)
	if new_value >= max_value:
		new_value = max_value
		emit_signal("filled")
	elif filled == max_value and new_value < max_value:
		emit_signal("unfilled")
	elif new_value < 0:
		new_value = 0

	filled = new_value
	if filled_label:
		filled_label.text = str(new_value)
	tween.interpolate_property(clock_texture, "value", null, new_value, 0.25, Tween.TRANS_BOUNCE, Tween.EASE_IN_OUT)
	tween.start()
	yield(tween, "tween_all_completed")
	save_clock()


func _set_max_value(value: int) -> void:
	max_value = value
	segments.text = str(max_value)
	if filled > max_value:
		self.filled = max_value
	if max_value <= 4:
		change_clock_texture(clock_texture, FOUR_CLOCK_TEXTURE_OVER, FOUR_CLOCK_TEXTURE_UNDER)
	elif max_value == 6:
		change_clock_texture(clock_texture, SIX_CLOCK_TEXTURE_OVER, SIX_CLOCK_TEXTURE_UNDER)
	elif max_value == 8:
		change_clock_texture(clock_texture, EIGHT_CLOCK_TEXTURE_OVER, EIGHT_CLOCK_TEXTURE_UNDER)
	elif max_value >= 12:
		change_clock_texture(clock_texture, TWELVE_CLOCK_TEXTURE_OVER, TWELVE_CLOCK_TEXTURE_UNDER)

	tween.interpolate_property(clock_texture, "max_value", null, value, 0.25, Tween.TRANS_BOUNCE, Tween.EASE_IN_OUT)
	tween.start()
	yield(tween, "tween_all_completed")
	save_clock()


func _set_clock_name(value: String) -> void:
	clock_name = value
	emit_signal("name_changed", value)
	save_clock()


func _set_locking_clock(value:String) -> void:
	if value:
		if value == self.id:
			return
		if locked_by_clock:
			if value == locked_by_clock:
				return
		if locking_clock:
			if value == locking_clock:
				return

	var old_locking_clock:NodeReference
	var new_locking_clock:NodeReference

	if locking_clock and GameData.clock_nodes.has(locking_clock):
		old_locking_clock = GameData.clock_nodes[locking_clock]
		old_locking_clock.send_method("unlock")
	if value and GameData.clock_nodes.has(value):
		new_locking_clock = GameData.clock_nodes[value]
		new_locking_clock.update_property("locked_by_clock", id)
	locking_clock = value


func _set_locked_by_clock(value:String) -> void:
	#Prevents cyclic locks
	if value:
		if value == self.id:
			return
		if locked_by_clock:
			if value == locked_by_clock:
				return
		if locking_clock:
			if value == locking_clock:
				return

	var old_locked_by_clock:NodeReference
	var old_value:String = locked_by_clock
	var new_locked_by_clock:NodeReference

	locked_by_clock = value
	if old_value and GameData.clock_nodes.has(old_value):
		old_locked_by_clock = GameData.clock_nodes[old_value]
		old_locked_by_clock.update_property("locking_clock", "")
		new_locked_by_clock.disconnect_from_members("name_changed", self, "_on_locked_by_clock_name_change")
		new_locked_by_clock.disconnect_from_members("filled", self, "_on_locked_by_clock_filled")
		new_locked_by_clock.disconnect_from_members("unfilled", self, "_on_locked_by_clock_unfilled")

	if value and GameData.clock_nodes.has(value):
		lock()
		new_locked_by_clock = GameData.clock_nodes[value]
		new_locked_by_clock.update_property("locking_clock", id)
		locked_by_container.visible = true
		new_locked_by_clock.connect_to_members("name_changed", self, "_on_locked_by_clock_name_change")
		new_locked_by_clock.connect_to_members("filled", self, "_on_locked_by_clock_filled")
		new_locked_by_clock.connect_to_members("unfilled", self, "_on_locked_by_clock_unfilled")
		locked_by_clock_label.text = new_locked_by_clock.get_property("clock_name")
		locked_by_clock_label.visible = true

	if not locked_by_clock:
		locked_by_container.visible = false
		locked_by_clock_label.text = ""
		unlock()


func _set_type(value)-> void:
	type = value
	emit_signal("type_changed", value)
	save_clock()


func _set_is_secret(value: bool) -> void:
	is_secret = value
	clock_line_edit.secret = value
	save_clock()


func _on_locked_by_clock_filled()-> void:
	self.unlock()


func _on_locked_by_clock_unfilled()-> void:
	self.lock()


func clear_locked_by_clock()-> void:
	locked_by_clock = ""
	locked_by_clock_label.text = ""
	locked_by_container.visible = false
	unlock()
	save_clock()


func clear_locking_clock()-> void:
	locking_clock = ""
	locking_clock_label.text = ""
	save_clock()


func _on_locking_clock_name_change(new_name: String)->void:
	locking_clock_label.text = new_name


func _on_locked_by_clock_name_change(new_name: String)->void:
	locked_by_clock_label.text = new_name


func change_clock_texture(node: TextureProgress, texture_over: Texture, texture_progress: Texture)->void:
	node.texture_under = texture_progress
	node.texture_progress = texture_progress
	node.texture_over = texture_over


func _on_PlusSegment_pressed() -> void:
	if max_value <=4: self.max_value = 6
	elif max_value == 6: self.max_value = 8
	elif max_value == 8: self.max_value = 12
	save_clock()


func _on_MinusSegment_pressed() -> void:
	if max_value <=6: self.max_value = 4
	elif max_value == 8: self.max_value = 6
	elif max_value == 12: self.max_value = 8
	save_clock()


func _on_Plus_pressed() -> void:
	self.filled += 1
	save_clock()


func _on_Minus_pressed() -> void:
	self.filled -= 1
	save_clock()


func _on_ClockTexture_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("left_click"):
		_on_Plus_pressed()
	if event.is_action_pressed("right_click"):
		_on_Minus_pressed()


func _on_ClockName_text_changed(new_text: String) -> void:
	self.clock_name = new_text


func _on_CheckBox_toggled(button_pressed: bool) -> void:
	self.is_secret = button_pressed


func _on_LockCheckBox_toggled(button_pressed: bool) -> void:
	if button_pressed:
		lock()
	else:
		unlock()
	Events.emit_clock_updated(self)


func _on_DisconnectButton_pressed() -> void:
	self.locked_by_clock = ""
	unlock()
	Events.emit_clock_updated(self)


func _on_DeleteButton_pressed() -> void:
	delete()


func _on_ClockTypeOption_item_selected(index: int) -> void:
	self.type = index


func _set_fill_color(color: Color)-> void:
	fill_color = color
	save_clock()


func _on_ColorPickerButton_color_changed(color: Color) -> void:
	self.fill_color = color
	clock_texture.tint_progress = color


func _on_LockingClockButton_pressed() -> void:
	#Create the link picker and pass it the clock that originiated it. display it. That is all.
	var popup_canvas = CanvasLayer.new()
	popup_canvas.layer = 100
	var locking_clock_picker = locking_clock_picker_scene.instance() as PopupMenu
#	var base_clock:Dictionary
#	for clock in GameData.clocks:
#		if clock.id == id:
#			base_clock = clock
	locking_clock_picker.base_clock = self
	Events.popup(locking_clock_picker)


func _set_scale(value:float)-> void:
	rect_scale = Vector2(value, value)
