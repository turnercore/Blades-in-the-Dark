extends Control
onready var overlay: = $OverlayBackground
var screens: Dictionary = {}

func _ready() -> void:

	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.visible = false

	Events.connect("popup", self, "_on_popup")
	Events.connect("popup_finished", self, "_on_popup_finished")
	Events.connect("main_screen_changed", self, "_on_main_screen_changed")

	for child in get_children():
		if child == overlay: continue
		var child_name = child.name.to_lower()
		screens[child_name] = child
		if child.has_signal("popup_hide"):
			child.connect("popup_hide", self, "_on_popup_hidden")
		else: print("error setting up popups")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("settings_menu"):
		change_screen_to("settings")


func change_screen_to(screen: String)-> void:
	screen = screen.to_lower()
	if screen in screens:
		if screens[screen] is Popup:
			print("using popup instead")
			screens[screen].popup()


func _on_main_screen_changed(screen: String) -> void:
	screen = screen.to_lower()
	if screens.has(screen):
		change_screen_to(screen)


func _on_popup(popup)-> void:
	$OverlayBackground.visible = true
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	if popup is Popup:
		add_child(popup)
		popup.popup()
	elif popup is String:
		change_screen_to(popup)


func _on_popup_hidden()-> void:
	Events.emit_signal("popup_finished")


func _on_popup_finished()-> void:
	overlay.visible = false
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

