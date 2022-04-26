class_name Clock
extends Control

const RAND_LIMIT: = 1000
const SAVE_INTERVAL: = 0.5

export (Texture) var FOUR_CLOCK_TEXTURE_UNDER
export (Texture) var FOUR_CLOCK_TEXTURE_OVER
export (Texture) var SIX_CLOCK_TEXTURE_UNDER
export (Texture) var SIX_CLOCK_TEXTURE_OVER
export (Texture) var EIGHT_CLOCK_TEXTURE_UNDER
export (Texture) var EIGHT_CLOCK_TEXTURE_OVER
export (Texture) var TWELVE_CLOCK_TEXTURE_UNDER
export (Texture) var TWELVE_CLOCK_TEXTURE_OVER

export (NodePath) onready var tween = get_node(tween) as Tween
export (NodePath) onready var segments = get_node(segments) as Label
export (NodePath) onready var filled_label = get_node(filled_label) as Label
export (NodePath) onready var clock_texture = get_node(clock_texture) as TextureProgress
export (NodePath) onready var clock_line_edit = get_node(clock_line_edit) as LineEdit
export (NodePath) onready var lock_texture = get_node(lock_texture) as TextureRect
export (NodePath) onready var locked_by_container = get_node(locked_by_container) as Container
export (NodePath) onready var locked_by_clock_label = get_node(locked_by_clock_label) as Label
export (NodePath) onready var unlocks_clock_label = get_node(unlocks_clock_label) as Label
export(NodePath) onready var clock_type_option = get_node(clock_type_option) as OptionButton


export (String) var id:String setget _set_id
export var clock_name:String = name setget _set_clock_name
export var locked: = false setget _set_locked
var locked_by_clock setget _set_locked_by_clock
var unlocks_clock setget _set_unlocks_clock
export var filled: = 0 setget _set_filled
export var max_value: = 4 setget _set_max_value
export var is_secret: bool = false setget _set_is_secret
var type:int setget _set_type
onready var fill_color:Color = clock_texture.tint_progress setget _set_fill_color
#var clock_data: = {
#	"id": id,
#	"clock_name": clock_name,
#	"filled": filled,
#	"max_value": max_value,
#	"locked": locked,
#	"locked_by_clock": locked_by_clock,
#	"unlocks_clock": unlocks_clock,
#	"type": type,
#	"is_secret": is_secret,
#	"fill_color": fill_color
#}

var is_setup:= false
var is_saving:= false

signal filled
signal unfilled
signal name_changed(new_name)
signal type_changed(type)

func _ready()->void:
	if not locked_by_clock:
		locked_by_container.visible = false

	for clock_type in Globals.CLOCK_TYPE:
		var type_str: String = str(clock_type).to_lower().replace("_", " ").capitalize()
		clock_type_option.add_item(type_str)


func setup(new_clock_data:Dictionary)->void:
	name = new_clock_data.clock_name
	clock_name = new_clock_data.clock_name
	clock_type_option.selected = new_clock_data.type
	self.id = new_clock_data.id
	for property in new_clock_data:
		if property == "clock_name" or property == "id":
			continue
		elif property in self:
			set(property, new_clock_data[property])
	visible = true
	is_setup = true


func save_clock()->void:
	if not is_setup or is_saving: return
	is_saving = true
	yield(get_tree().create_timer(SAVE_INTERVAL), "timeout")
	Events.emit_clock_updated(self)
	is_saving = false


func setup_from_data(clock_data:Dictionary)-> void:
	for property in clock_data:
		set(property, clock_data[property])
	is_setup = true
	visible = true


func package_clock_data()->Dictionary:
	var clock_data: = {
		"id": id,
		"name": clock_name,
		"filled": filled,
		"max_value": max_value,
		"locked": locked,
		"locked_by_clock": locked_by_clock,
		"unlocks_clock": unlocks_clock,
		"type": type,
		"is_secret": is_secret
	}
	return clock_data


func link_to_clock(clock: Clock)->void:
	clock.linked_clock = self
	clock.locked = true
	connect("filled", clock, "unlock")


func unlock()->void:
	if locked:
		self.locked = false
		save_clock()


func lock()->void:
	if not locked:
		self.locked = true
		save_clock()


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


func _set_id(value:String)->void:
	if value == "new_id":
		randomize()
		var unique_id_helper:int = 0
		var new_id = clock_name + "_" + str((randi() % RAND_LIMIT))
		yield(get_tree().create_timer(SAVE_INTERVAL), "timeout")
		while GameData.clocks.has(new_id):
			print("same clock id found in clocks, what are the odds, trying again")
			# warning-ignore:integer_division
			unique_id_helper += randi() % (RAND_LIMIT/100)
			new_id = clock_name + "_" + str((randi() % RAND_LIMIT)+unique_id_helper)
		id = new_id
	else:
		id = value
	save_clock()


func _set_filled(new_value: int) -> void:
	if new_value >= max_value:
		new_value = max_value
		emit_signal("filled")
	elif filled == max_value and new_value < max_value:
		emit_signal("unfilled")
	elif new_value < 0:
		new_value = 0

	filled = new_value
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


func _set_unlocks_clock(value) -> void:
	if value:
		if unlocks_clock:
			if value == unlocks_clock:
				return
		if locked_by_clock:
			if value == locked_by_clock:
				return

	if unlocks_clock:
		if unlocks_clock.is_connected("name_changed", self, "_on_unlocks_clock_name_change"):
			unlocks_clock.disconnect("name_changed", self, "_on_unlocks_clock_name_change")
		unlocks_clock.clear_locked_by_clock()

	unlocks_clock = value
	save_clock()

	if not unlocks_clock:
		unlocks_clock_label.text = ""
		return

	if unlocks_clock and not unlocks_clock.is_connected("name_changed", self, "_on_unlocks_clock_name_change"):
		unlocks_clock.connect("name_changed", self, "_on_unlocks_clock_name_change")
	unlocks_clock_label.text = unlocks_clock.clock_name if unlocks_clock else ""


func _set_locked_by_clock(value) -> void:
	if value:
		if unlocks_clock:
			if value == unlocks_clock:
				return
		elif locked_by_clock:
			if value == locked_by_clock:
				return

	if locked_by_clock:
		locked_by_clock_label.text = ""
		self.locked_by_container.visible = false
		if locked_by_clock.is_connected("name_changed", self, "_on_locked_by_clock_name_change"):
			locked_by_clock.disconnect("name_changed", self, "_on_locked_by_clock_name_change")
		locked_by_clock.clear_unlocks_clock()

	locked_by_clock = value
	save_clock()

	if not locked_by_clock:
		locked_by_container.visible = false
		locked_by_clock_label.text = ""
		unlock()
		return
	else:
		locked_by_container.visible = true
	if not locked_by_clock.is_connected("name_changed", self, "_on_locked_by_clock_name_change"):
		locked_by_clock.connect("name_changed", self, "_on_locked_by_clock_name_change")
	if not locked_by_clock.is_connected("filled", self, "_on_locked_by_clock_filled"):
		locked_by_clock.connect("filled", self, "_on_locked_by_clock_filled")
	if not locked_by_clock.is_connected("unfilled", self, "_on_locked_by_clock_unfilled"):
		locked_by_clock.connect("unfilled", self, "_on_locked_by_clock_unfilled")
	locked_by_clock_label.text = locked_by_clock.clock_name


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


func clear_unlocks_clock()-> void:
	unlocks_clock = null
	unlocks_clock_label.text = ""
	save_clock()


func clear_locked_by_clock()-> void:
	locked_by_clock = null
	locked_by_clock_label.text = ""
	locked_by_container.visible = false
	unlock()
	save_clock()


func _on_unlocks_clock_name_change(new_name: String)->void:
	unlocks_clock_label.text = new_name


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
	print(clock_name)


func _on_CheckBox_toggled(button_pressed: bool) -> void:
	self.is_secret = button_pressed


func _on_LockCheckBox_toggled(button_pressed: bool) -> void:
	if button_pressed:
		lock()
	else:
		unlock()
	Events.emit_clock_updated(self)


func _on_DisconnectButton_pressed() -> void:
	self.locked_by_clock = false
	unlock()
	Events.emit_clock_updated(self)


func _on_DeleteButton_pressed() -> void:
	if locked_by_clock: locked_by_clock.clear_unlocks_clock()
	if unlocks_clock: unlocks_clock.clear_locked_by_clock()
	Events.emit_clock_removed(self.id)
	queue_free()


func _on_ClockTypeOption_item_selected(index: int) -> void:
	self.type = index


func _set_fill_color(color: Color)-> void:
	fill_color = color
	save_clock()


func _on_ColorPickerButton_color_changed(color: Color) -> void:
	self.fill_color = color
	clock_texture.tint_progress = color
