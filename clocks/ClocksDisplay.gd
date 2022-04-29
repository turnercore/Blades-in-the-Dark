extends PopupScreen
const BASE_CLOCK_SIZE: = Vector2(1, 1)
var DEFAULT_CLOCK_DATA: = {
		"id": "",
		"clock_name": "",
		"filled" : 0,
		"max_value" : 4,
		"locked" : false,
		"locking_clock" : "",
		"locked_by_clock": "",
		"type" : Clock.CLOCK_TYPE.OBSTACLE,
		"is_secret": false,
		"fill_color": Color.black
		}

export (PackedScene) var clock_scene
onready var grid: = $ScrollContainer/VBoxContainer/Clocks
onready var add_clock_button: = $ScrollContainer/VBoxContainer/Settings/AddClock
onready var clock_sort_button: = $ScrollContainer/VBoxContainer/Settings/ClockSort

var current_clock_scale: = BASE_CLOCK_SIZE
var current_type_displayed: = 0
var displayed_clocks: = []


func _ready() -> void:
	$ScrollContainer/VBoxContainer/Settings/GridColumnOption.selected = grid.columns
	for type in Clock.CLOCK_TYPE:
		var type_str: String = str(type).to_lower().replace("_", " ").capitalize()
		clock_sort_button.add_item(type_str)
	connect_to_clock_updates()


func connect_to_clock_updates()-> void:
	GameData.clock_library.connect("resource_added", self, "_on_clock_added")
	for clock in GameData.clock_library.get_catalogue():
		if not clock.is_connected("property_changed", self, "_on_clock_property_changed"):
			clock.connect("property_changed", self, "_on_clock_property_changed", [clock])


func clear_clocks()-> void:
	for child in grid.get_children():
		if child != add_clock_button:
			child.queue_free()


func add_clock(data = null)-> void:
	var clock:NetworkedResource

	#Brand new clock being added
	if not data:
		data = DEFAULT_CLOCK_DATA.duplicate(true)
		data.type = current_type_displayed
		data.id = Globals.generate_id(5)

	if data is Dictionary:
		clock = GameData.clock_library.add(data)
	elif data is NetworkedResource:
		clock = data

	if not clock.is_connected("property_changed", self, "_on_clock_property_changed"):
			clock.connect("property_changed", self, "_on_clock_property_changed", [clock])
	if displayed_clocks.has(clock.id):
		return

	if clock.get_property("type") == current_type_displayed:
		var new_clock: Clock = clock_scene.instance()
		new_clock.clock = clock
		grid.add_child(new_clock)
		new_clock.setup(clock)
		displayed_clocks.append(clock.id)


func _on_displayed_clock_property_changed(property:String, value, clock:NetworkedResource)-> void:
	match property:
		"type":
			if value == current_type_displayed:
				add_clock(clock)


func _on_clock_added(clock:NetworkedResource)-> void:
	add_clock(clock)


func refresh_clocks()->void:#This :=[] looks like a screaming robot
	clear_clocks()
	for clock in GameData.clock_library.get_catalogue():
		if clock.get_property("type") == current_type_displayed:
			add_clock(clock)


func remove_clock(clock)-> void:
	grid.remove_child(clock)


func _on_AddClock_pressed() -> void:
	add_clock(null)


func _on_save_loaded(_save_game)->void:
	refresh_clocks()


func _on_ClockSort_item_selected(type: int) -> void:
	current_type_displayed = type
	refresh_clocks()


func _on_GridColumnOption_item_selected(value: int) -> void:
	grid.columns = value
