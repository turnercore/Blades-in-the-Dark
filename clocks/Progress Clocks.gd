extends Container

export (PackedScene) var clock_scene
onready var grid: GridContainer = $Clocks
onready var button: Button = $Clocks/AddClock


func _ready() -> void:
	GameSaver.connect("save_loaded", self, "_on_save_loaded")
	add_loaded_clocks()

func clear_clocks()-> void:
	pass


func add_loaded_clocks()->void:
	pass


func _on_AddClock_pressed() -> void:
	var new_clock: Clock = clock_scene.instance()
	new_clock.rect_scale = Vector2(0.5, 0.5)
	grid.add_child(new_clock)
	grid.move_child(button, grid.get_child_count() - 1)
	GameSaver.save_game.add_clock(new_clock)


func _on_save_loaded(_save_game)->void:
	add_loaded_clocks()
