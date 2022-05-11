extends Control
export (NodePath) onready var overlay = get_node(overlay) as ColorRect
var screens: Dictionary = {}
var popups_active:int = 0 setget _set_popups_active

func _ready() -> void:
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.visible = false

	Events.connect("popup", self, "_on_popup")
	Events.connect("popup_finished", self, "_on_popup_finished")
	Events.connect("all_popups_finished", self, "_on_all_popups_finished")

	for child in get_children():
		if child == overlay: continue
		var child_name = child.name.to_lower()
		screens[child_name] = child
		if child.has_signal("popup_hide"):
			child.connect("popup_hide", self, "_on_popup_hidden")
		else: print("error setting up popups")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		change_screen_to("settings")


func change_screen_to(screen: String)-> void:
	screen = screen.to_lower()
	if screen in screens:
		if screens[screen] is Node:
			screens[screen].popup()


func _on_popup(popup, use_overlay: = false)-> void:
	if use_overlay:
		overlay.visible = true
		overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	if popup is Node:
		add_child(popup)
		popup.popup()
	elif popup is String:
		change_screen_to(popup)

	self.popups_active += 1


func _on_popup_hidden()-> void:
	Events.emit_signal("popup_finished")


func _on_popup_finished()-> void:
	self.popups_active -= 1

func _set_popups_active(value: int)-> void:
	popups_active = int(clamp(value, 0, 100000))
	if popups_active == 0:
		overlay.visible = false
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		Events.emit_signal("all_popups_finished")

func _on_all_popups_finished()-> void:
	if popups_active != 0:
		self.popups_active = 0









