extends Container

export (PackedScene) var clock_scene
onready var grid: GridContainer = $Clocks
onready var button: Button = $Clocks/AddClock

func _on_AddClock_pressed() -> void:
	var new_clock: Clock = clock_scene.instance()
	new_clock.rect_scale = Vector2(0.5, 0.5)
	grid.add_child(new_clock)
	grid.move_child(button, grid.get_child_count() - 1)
