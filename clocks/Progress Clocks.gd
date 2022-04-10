extends Container

var DEFAULT_CLOCK_DATA: = {
		"clock_name": "clock",
		"id": "new_id",
		"filled": 0,
		"max_value": 4,
		"locked": false,
		"locked_by_clock": null,
		"unlocks_clock": null,
		"type": Globals.CLOCK_TYPE.OBSTACLE,
		"is_secret": false
		}

export (PackedScene) var clock_scene
onready var grid: = $VBoxContainer/Clocks
onready var add_clock_button: = $VBoxContainer/Settings/AddClock


func _ready() -> void:
	GameData.connect("clocks_loaded", self, "_on_clocks_loaded")


func clear_clocks()-> void:
	for child in grid.get_children():
		if child != add_clock_button:
			child.queue_free()


func add_clock(clock_data:={})-> void:
	var new_clock: Clock = clock_scene.instance()
	if clock_data.empty():
		clock_data = DEFAULT_CLOCK_DATA


	new_clock.rect_scale = Vector2(0.5, 0.5)
	grid.add_child(new_clock)
	new_clock.setup(clock_data)



func add_loaded_clocks(clocks:={})->void:#This :=[] looks like a screaming robot
	clear_clocks()
	if clocks.empty(): clocks = GameData.clocks
	for clock in clocks:
		add_clock(clock)


func _on_clocks_loaded(clocks:Dictionary)->void:
	print("clocks loaded")
	print(clocks)
	add_loaded_clocks(clocks)


func _on_AddClock_pressed() -> void:
	add_clock()


func _on_save_loaded(_save_game)->void:
	add_loaded_clocks(GameData.clocks)
