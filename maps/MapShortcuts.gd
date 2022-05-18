extends VBoxContainer

export (PackedScene) var shortcut_scene

#var test_shortcuts:= [{"pos": Vector2(150, 150), "location":"Secret lair"}, {"pos": Vector2(1000,500)}, {"pos": Vector2(0,0)}]

func _ready() -> void:
	setup()
	GameData.connect("map_shortcut_added", self, "setup")
	GameData.connect("map_shortcut_removed", self, "setup")


func setup()-> void:
	var i = 1

	for child in get_children():
		child.queue_free()

	for shortcut in GameData.map_shortcuts:
		var new_shortcut = shortcut_scene.instance()
		new_shortcut.pos = shortcut if shortcut is Vector2 else str2var(shortcut)
		new_shortcut.text = str(i)
		new_shortcut.location = GameData.location_library.search("pos", shortcut).front()
		new_shortcut.description = new_shortcut.location.get_property("description")
		new_shortcut.connect("pressed", self, "_on_shortcut_pressed", [shortcut])
		add_child(new_shortcut)
		i+=1


func _on_shortcut_pressed(pos: Vector2)-> void:
	Events.move_camera(Globals.map_to_world(pos))
