extends PopupMenu

const CLOCK_GROUP:String = "clocks"
#base_clock is passed when this is created
var base_clock: Clock
var linked_clock: Clock

onready var clocks: Array = get_tree().get_nodes_in_group(CLOCK_GROUP)
var clock_items: Array = []

#Get all the clocks in the game, when the user clicks one return it to the clock that called it.
func _ready() -> void:
	clear()
	print(base_clock)

	for clock in clocks:
		if clock == base_clock: continue
		self.add_item(clock.clock_name)
		clock_items.append(clock)



func _on_LinkClockPicker_index_pressed(index: int) -> void:
	linked_clock = clock_items[index]
	base_clock.unlocks_clock = linked_clock
	linked_clock.unlocked_by_clock = base_clock
	linked_clock.locked = true
	print(linked_clock)
	get_parent().queue_free()
	self.queue_free()
