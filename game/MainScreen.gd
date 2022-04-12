extends Control

var current_screen: Node
var screens: Dictionary = {}

func _ready() -> void:
	Events.connect("main_screen_changed", self, "_on_main_screen_changed")

	for child in get_children():
		var child_name = child.name.to_lower()
		screens[child_name] = child

	current_screen = get_child(0)
	current_screen.visible = true


func change_screen_to(screen: String)-> void:
	if screens[screen] is Popup:
		print("using popup instead")
		screens[screen].popup()
	else:
		current_screen.visible = false
		screens[screen].visible = true
		current_screen = screens[screen]


func _on_main_screen_changed(screen: String) -> void:
	screen = screen.to_lower()
	if screens.has(screen):
		change_screen_to(screen)
