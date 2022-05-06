extends PopupMenu

#base_clock is passed when this is created
var base_clock
var clock_ids:= []
#Get all the clocks in the game, when the user clicks one return it to the clock that called it.
func _ready() -> void:
	clear()
	for clock_id in GameData.clock_nodes:
		if clock_id == base_clock.id: continue
		elif clock_id == base_clock.locking_clock: continue
		elif clock_id == base_clock.locked_by_clock: continue
		else:
			var clock_name:String = GameData.clock_nodes[clock_id].get_property("clock_name")
			add_item(clock_name)
			clock_ids.append(clock_id)


func _on_LinkClockPicker_index_pressed(index: int) -> void:
	var clock_picked = clock_ids[index]
	base_clock.locking_clock = clock_picked
	hide()
	self.queue_free()
