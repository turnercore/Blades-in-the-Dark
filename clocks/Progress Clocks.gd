extends Container

const DEFAULT_CLOCK_DATA: = {
		"id": 0,
		"clock_name": "clock",
		"filled": 0,
		"max_value": 4,
		"locked": false,
		"locked_by_clock": null, #-1 if it's not locked by anything, otherwise clock id
		"unlocks_clock": null,
		"type": "Obstacle Clock",
		"is_secret": false
		}

export (PackedScene) var clock_scene
onready var grid: GridContainer = $Clocks
onready var add_clock_button: Button = $Clocks/AddClock


func _ready() -> void:
	GameData.connect("clocks_loaded", self, "_on_clocks_loaded")


func clear_clocks()-> void:
	for child in grid:
		if child != add_clock_button:
			child.queue_free()


func add_clock(clock_data:Dictionary={})-> void:
	var new_clock: Clock = clock_scene.instance()
	if clock_data == {}:
		clock_data = DEFAULT_CLOCK_DATA

	for property in clock_data:
		if property in new_clock:
			new_clock.set(property, clock_data[property])

	new_clock.rect_scale = Vector2(0.5, 0.5)
	grid.add_child(new_clock)
	grid.move_child(add_clock_button, grid.get_child_count())


func add_loaded_clocks(clocks:=[])->void:#This :=[] looks like a screaming robot
	clear_clocks()
	if clocks.empty(): clocks = GameData.clocks
	for clock in clocks:
		add_clock(clock)


func _on_clocks_loaded(clocks:Array)->void:
	add_loaded_clocks(clocks)


func _on_AddClock_pressed() -> void:
	add_clock()


func _on_save_loaded(_save_game)->void:
	add_loaded_clocks()
