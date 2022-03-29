extends Container

onready var item_list: ItemList = $ItemList
export (NodePath) onready var main_screen = get_node(main_screen) as Container if main_screen else null
export (int, 0, 200) var trans_distance: int = 100
onready var tween: Tween = $Tween
var hidden: bool = false
var animating: bool = false
var hovered: bool = false
onready var default_position: Vector2 = rect_position
onready var hidden_position: Vector2 = rect_position + Vector2(trans_distance, 0)


func _ready() -> void:
	if main_screen:
		for child in main_screen.get_children():
			item_list.add_item(child.name)
	connect_to_detection_recursive(self)
	hide_controls()


func connect_to_detection_recursive(node:Node)->void:
	if node.has_signal("focus_entered"):
		node.connect("focus_entered", self, "_on_focus_entered")
	if node.has_signal("focus_exited"):
		node.connect("focus_exited", self, "_on_focus_exited")
	if node.has_signal("mouse_entered"):
		node.connect("mouse_entered", self, "_on_mouse_entered")
	if node.has_signal("mouse_exited"):
		node.connect("mouse_exited", self, "_on_mouse_exited")

	for child in node.get_children():
		connect_to_detection_recursive(child)


func _on_ItemList_item_selected(index: int) -> void:
	var selected = item_list.get_item_text(index).to_lower()
	Events.emit_signal("main_screen_changed", selected)


func hide_controls()->void:
	yield(get_tree().create_timer(1), "timeout")
	if hovered: return

	if not hidden and not animating:
		tween.interpolate_property(
			self,
			"rect_position",
			default_position,
			hidden_position,
			0.45,
			Tween.TRANS_CUBIC,
			Tween.EASE_IN_OUT)

		tween.interpolate_property(
			self,
			"modulate",
			null,
			Color(1, 1, 1, 0.4),
			0.1,
			Tween.TRANS_CUBIC,
			Tween.EASE_IN_OUT
			)

		tween.start()
		animating = true
		yield(tween, "tween_completed")
		animating = false
		hidden = true

func show_controls()-> void:
	if hidden and not animating:
		tween.interpolate_property(
			self,
			"rect_position",
			hidden_position,
			default_position,
			0.45,
			Tween.TRANS_CUBIC,
			Tween.EASE_IN_OUT)

		tween.interpolate_property(
			self,
			"modulate",
			null,
			Color(1, 1, 1, 1),
			0.1,
			Tween.TRANS_CUBIC,
			Tween.EASE_IN_OUT
			)

		tween.start()
		animating = true
		yield(tween, "tween_completed")
		animating = false
		hidden = false

func _on_focus_entered()-> void:
	hovered = true
	show_controls()

func _on_focus_exited()-> void:
	hovered = false
	hide_controls()

func _on_mouse_entered()-> void:
	hovered = true
	show_controls()

func _on_mouse_exited()-> void:
	hovered = false
	hide_controls()
