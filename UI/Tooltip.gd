extends Position2D

const DISMISS_TIMING: = 1.5
const DISAPPEAR_TIMING: = 0.4
const HOVER_TIMING: = 0.75
const OFFSET:Vector2 = Vector2(25.0, -15.0)

onready var tween: = $Tween
onready var dismiss_timer: = $DismissTimer
onready var hover_timer: = $HoverTimer
export (PackedScene) var frozen_tooltip
export (NodePath) onready var info_label = get_node(info_label) as RichTextLabel
export (NodePath) onready var title_label = get_node(title_label) as RichTextLabel
export (NodePath) onready var tooltip_container = get_node(tooltip_container) as PanelContainer
var current_tooltip:String setget _set_current_tooltip
var current_title:String setget _set_current_title
var hover_mode: = true
var should_show: = false
var freeze_lock: = false


func _ready() -> void:
	Events.connect("info_broadcasted", self, "_on_info_broadcasted")
	Events.connect("popup_layer_ready", self, "_on_popup_layer_ready")
	hover_timer.connect("timeout", self, "_on_hover_timer_timeout")
	tooltip_container.modulate.a = 0



func _on_popup_layer_ready()-> void:
	remove_child(tooltip_container)
	Events.emit_signal("tooltip_container_transfered", tooltip_container)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("tooltip_hide"):
		if hover_mode:
			hover_mode = false
			fade_in()
		elif not hover_mode:
			should_show = false
			fade_out()
			hover_mode = true

	if event.is_action_pressed("tooltip_freeze"):
		if not freeze_lock:
			freeze_tooltip()
			freeze_lock = true
	if event.is_action_released("tooltip_freeze"):
		freeze_lock = false


func freeze_tooltip()-> void:
	var new_frozen_tooltip: DragableWindow = frozen_tooltip.instance()
#	$TooltipLayer.add_child(new_frozen_tooltip)
	new_frozen_tooltip.title = title_label.text
	new_frozen_tooltip.description = info_label.text
#	new_frozen_tooltip.rect_position = get_viewport().get_mouse_position()
	Events.emit_signal("tooltip_frozen", new_frozen_tooltip)



func _on_info_broadcasted(info: String)->void:
	if info == "":
		dismiss_timer.start(DISMISS_TIMING)
	else:
		info_label.text = info
		dismiss_timer.stop()
		fade_in()


func fade_in()-> void:
	if hover_mode:
		should_show = true
	tween.interpolate_property(
		tooltip_container,
		"modulate",
		null,
		Color(1,1,1,1),
		DISAPPEAR_TIMING,
		Tween.TRANS_QUART,
		Tween.EASE_OUT
	)
	tween.start()
	tooltip_container.queue_sort()


func fade_out()-> void:
	#If this dismiss timer is running just skip this
	if hover_mode:
		should_show = false
		if not dismiss_timer.is_stopped():
			return
		else:
			dismiss_timer.start(DISMISS_TIMING)
			yield(dismiss_timer, "timeout")
			if should_show:
				return
	tween.interpolate_property(
		tooltip_container,
		"modulate",
		null,
		Color(1,1,1,0),
		DISAPPEAR_TIMING,
		Tween.TRANS_QUART,
		Tween.EASE_OUT
	)
	tween.start()
	tooltip_container.queue_sort()


func _process(_delta: float) -> void:
	tooltip_container.rect_position = get_viewport().get_mouse_position() + OFFSET


func _on_DismissTimer_timeout() -> void:
	fade_out()


func _set_current_tooltip(value:String)-> void:
	current_tooltip = value.c_unescape().replace("_", " ")
	info_label.text = current_tooltip


func _set_current_title(value:String)-> void:
	current_title = value.c_unescape().replace("_", " ")
	title_label.text = current_title


func display_tooltip(title:String="", tooltip:String="")-> void:
	self.current_tooltip = tooltip
	self.current_title = title
	if hover_mode and hover_timer.is_stopped():
		should_show = true
		hover_timer.start(HOVER_TIMING)


func finish_tooltip(_title:String="", _tooltip:String="")-> void:
	hover_timer.stop()
	if hover_mode:
		fade_out()


func _on_hover_timer_timeout()-> void:
	fade_in()
