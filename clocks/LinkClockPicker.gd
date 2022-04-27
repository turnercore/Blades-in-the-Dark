extends PopupMenu

const CLOCK_GROUP:String = "clocks"
#base_clock is passed when this is created
var base_clock
var linked_clock
var clock_items: Array = []

#Get all the clocks in the game, when the user clicks one return it to the clock that called it.
func _ready() -> void:
	clear()
	for clock in GameData.clocks:
		if clock == base_clock: continue
		if clock == base_clock.locking_clock: continue
		if clock == base_clock.locked_by_clock: continue
		self.add_item(clock.clock_name)
		clock_items.append(clock)


func _on_LinkClockPicker_index_pressed(index: int) -> void:
	var clock_picked = clock_items[index]
	base_clock.locking_clock = clock_picked
	clock_picked.locked_by_clock = base_clock
	hide()
	self.queue_free()
