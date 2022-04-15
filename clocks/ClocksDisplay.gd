extends Popup
const BASE_CLOCK_SIZE: = Vector2(1, 1)
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
onready var grid: = $ScrollContainer/VBoxContainer/Clocks
onready var add_clock_button: = $ScrollContainer/VBoxContainer/Settings/AddClock
onready var clock_sort_button: = $ScrollContainer/VBoxContainer/Settings/ClockSort

var current_clock_scale: = BASE_CLOCK_SIZE
var current_type_displayed: = 0


func _ready() -> void:
	$ScrollContainer/VBoxContainer/Settings/GridColumnOption.selected = grid.columns
	GameData.connect("clocks_loaded", self, "_on_clocks_loaded")
	for type in Globals.CLOCK_TYPE:
		var type_str: String = str(type).to_lower().replace("_", " ").capitalize()
		clock_sort_button.add_item(type_str)


func clear_clocks()-> void:
	for child in grid.get_children():
		if child != add_clock_button:
			child.queue_free()


func add_clock(clock_data:={})-> void:
	var new_clock: Clock = clock_scene.instance()
	if clock_data.empty():
		clock_data = DEFAULT_CLOCK_DATA
	new_clock.rect_scale = current_clock_scale
	grid.add_child(new_clock)
	new_clock.setup(clock_data)
	new_clock.connect("type_changed", self, "_on_clock_type_changed")


func add_loaded_clocks(clocks:={}, type:int= 0)->void:#This :=[] looks like a screaming robot
	clear_clocks()
	if clocks.empty(): clocks = GameData.clocks
	for clock in clocks:
		if type > 0:
			if clocks[clock].type == type:
				add_clock(clocks[clock])
		else:
			add_clock(clocks[clock])


func remove_clock(clock)-> void:
	clock.queue_free()


func _on_clocks_loaded(clocks:Dictionary)->void:
	add_loaded_clocks(clocks)


func _on_AddClock_pressed() -> void:
	add_clock()


func _on_save_loaded(_save_game)->void:
	add_loaded_clocks(GameData.clocks)


func _on_ClockSort_item_selected(type: int) -> void:
	current_type_displayed = type
	clear_clocks()
	add_loaded_clocks(GameData.clocks, type)


func _on_clock_type_changed(type: int, clock) -> void:
	if current_type_displayed == 0: return
	elif current_type_displayed == type: return
	else: remove_clock(clock)


func _on_ScaleSlider_value_changed(value: float) -> void:
	for clock in grid.get_children():
		current_clock_scale = BASE_CLOCK_SIZE * (value / 50)
		clock.rect_scale = current_clock_scale


func _on_GridColumnOption_item_selected(value: int) -> void:
	grid.columns = value
