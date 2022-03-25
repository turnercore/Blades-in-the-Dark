extends Button

export (PackedScene) onready var link_picker_scene
export (NodePath) onready var clock = get_node_or_null(clock) as Clock if clock else null


func _on_UnlocksClockButton_pressed() -> void:
	if not clock: return
	#Create the link picker and pass it the clock that originiated it. display it. That is all.
	var popup_canvas = CanvasLayer.new()
	popup_canvas.layer = 100
	var link_picker = link_picker_scene.instance() as PopupMenu
	link_picker.base_clock = clock
	popup_canvas.add_child(link_picker)
	get_tree().root.add_child(popup_canvas)
	link_picker.visible = true
