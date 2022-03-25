class_name Clock
extends Control

export (bool) var locked: = false setget _set_locked
export (String) var clock_name:String = "clock" + str(randi()%100) setget _set_clock_name

export (Texture) var FOUR_CLOCK_TEXTURE_UNDER
export (Texture) var FOUR_CLOCK_TEXTURE_OVER
export (Texture) var SIX_CLOCK_TEXTURE_UNDER
export (Texture) var SIX_CLOCK_TEXTURE_OVER
export (Texture) var EIGHT_CLOCK_TEXTURE_UNDER
export (Texture) var EIGHT_CLOCK_TEXTURE_OVER
export (Texture) var TWELVE_CLOCK_TEXTURE_UNDER
export (Texture) var TWELVE_CLOCK_TEXTURE_OVER

export (NodePath) onready var tween = get_node_or_null(tween) as Tween if tween else null
export (NodePath) onready var segments = get_node_or_null(segments) as Label if segments else null
export (NodePath) onready var filled_label = get_node_or_null(filled_label) as Label if filled_label else null
export (NodePath) onready var clock_texture = get_node_or_null(clock_texture) as TextureProgress if clock_texture else null
export (NodePath) onready var clock_line_edit = get_node_or_null(clock_line_edit) as LineEdit if clock_line_edit else null
export (NodePath) onready var lock_texture = get_node_or_null(lock_texture) as TextureRect if lock_texture else null
onready var unlocked_by_container: Container = $CenterContainer/HBoxContainer/EditWidgetContainer/VBoxContainer5/UnlockedByContainer
onready var unlocked_by_clock_label: Label = $CenterContainer/HBoxContainer/EditWidgetContainer/VBoxContainer5/UnlockedByContainer/UnlockedByClockLabel
onready var unlocks_clock_label: Label = $CenterContainer/HBoxContainer/EditWidgetContainer/HBoxContainer/UnlocksClockLabel
var unlocked_by_clock setget _set_unlocked_by_clock
var unlocks_clock setget _set_unlocks_clock


export (int) var filled: = 0 setget _set_filled
export (int) var max_value: = 4 setget _set_max_value

export (bool) var is_secret: bool = false setget _set_is_secret
signal filled
signal emptied
signal name_changed(new_name)


func _ready()->void:
	self.max_value = 4
	self.filled = 0
	if not unlocked_by_clock:
		unlocked_by_container.visible = false


func link_to_clock(clock: Clock)->void:
	clock.linked_clock = self
	clock.locked = true
	connect("filled", clock, "unlock")


func unlock()->void:
	if locked:
		self.locked = false

func lock()->void:
	if not locked:
		self.locked = true


func _set_locked(value: bool)->void:
	var locked_check_box: = 	$CenterContainer/HBoxContainer/EditWidgetContainer/VBoxContainer5/HBoxContainer/LockCheckBox
	locked = value
	locked_check_box.pressed = value

	if locked:
		clock_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lock_texture.visible = true

	elif not locked:
		clock_texture.mouse_filter = Control.MOUSE_FILTER_STOP
		lock_texture.visible = false


func _set_filled(new_value: int) -> void:
	if new_value >= max_value:
		new_value = max_value
		emit_signal("filled")

	if new_value < 0:
		new_value = 0
		emit_signal("emptied")

	filled = new_value
	filled_label.text = str(new_value)
	tween.interpolate_property(clock_texture, "value", null, new_value, 0.25, Tween.TRANS_BOUNCE, Tween.EASE_IN_OUT)
	tween.start()


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

func _set_clock_name(value: String) -> void:
	emit_signal("name_changed", value)
	clock_line_edit.text = value


func _set_unlocks_clock(value) -> void:
	if value:
		if unlocks_clock:
			if value == unlocks_clock:
				return
		if unlocked_by_clock:
			if value == unlocked_by_clock:
				return

	if unlocks_clock:
		if unlocks_clock.is_connected("name_changed", self, "_on_unlocks_clock_name_change"):
			unlocks_clock.disconnect("name_changed", self, "_on_unlocks_clock_name_change")
		unlocks_clock.clear_unlocked_by_clock()

	unlocks_clock = value

	if not unlocks_clock:
		unlocks_clock_label.text = ""
		return

	if unlocks_clock and not unlocks_clock.is_connected("name_changed", self, "_on_unlocks_clock_name_change"):
		unlocks_clock.connect("name_changed", self, "_on_unlocks_clock_name_change")
	unlocks_clock_label.text = unlocks_clock.clock_name if unlocks_clock else ""

func _set_unlocked_by_clock(value) -> void:
	if value:
		if unlocks_clock:
			if value == unlocks_clock:
				return
		if unlocked_by_clock:
			if value == unlocked_by_clock:
				return


	if unlocked_by_clock:
		unlocked_by_clock_label.text = ""
		self.unlocked_by_container.visible = false
		if unlocked_by_clock.is_connected("name_changed", self, "_on_unlocked_by_clock_name_change"):
			unlocked_by_clock.disconnect("name_changed", self, "_on_unlocked_by_clock_name_change")
		unlocked_by_clock.clear_unlocks_clock()


	unlocked_by_clock = value

	if not unlocked_by_clock:
		unlocked_by_container.visible = false
		unlocked_by_clock_label.text = ""
		unlock()
		return

	else:
		unlocked_by_container.visible = true
	if not unlocked_by_clock.is_connected("name_changed", self, "_on_unlocked_by_clock_name_change"):
		unlocked_by_clock.connect("name_changed", self, "_on_unlocked_by_clock_name_change")
	unlocked_by_clock_label.text = unlocked_by_clock.clock_name


func clear_unlocks_clock()-> void:
	unlocks_clock = false
	unlocks_clock_label.text = ""

func clear_unlocked_by_clock()-> void:
	unlocked_by_clock = false
	unlocked_by_clock_label.text = ""
	unlocked_by_container.visible = false

func _on_unlocks_clock_name_change(new_name: String)->void:
	unlocks_clock_label.text = new_name

func _on_unlocked_by_clock_name_change(new_name: String)->void:
	unlocked_by_clock_label.text = new_name

func change_clock_texture(node: TextureProgress, texture_over: Texture, texture_progress: Texture)->void:
		node.texture_under = texture_progress
		node.texture_progress = texture_progress
		node.texture_over = texture_over


func _set_is_secret(value: bool) -> void:
	is_secret = value
	clock_line_edit.secret = value


func _on_PlusSegment_pressed() -> void:
	if max_value <=4: self.max_value = 6
	elif max_value == 6: self.max_value = 8
	elif max_value == 8: self.max_value = 12
	else: return


func _on_MinusSegment_pressed() -> void:
	if max_value <=6: self.max_value = 4
	elif max_value == 8: self.max_value = 6
	elif max_value == 12: self.max_value = 8
	else: return


func _on_Plus_pressed() -> void:
	self.filled += 1


func _on_Minus_pressed() -> void:
	self.filled -= 1


func _on_ClockTexture_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("left_click"):
		_on_Plus_pressed()
	if event.is_action_pressed("right_click"):
		_on_Minus_pressed()


func _on_ClockName_text_changed(new_text: String) -> void:
	if clock_name != new_text:
		clock_name = new_text


func _on_CheckBox_toggled(button_pressed: bool) -> void:
	self.is_secret = button_pressed


func _on_LockCheckBox_toggled(button_pressed: bool) -> void:
	if button_pressed:
		lock()
	else:
		unlock()


func _on_DisconnectButton_pressed() -> void:
	self.unlocked_by_clock = false
	unlock()
