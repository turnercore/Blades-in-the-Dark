extends Container

onready var item_list: ItemList = $ItemList

#
#func _process(delta: float) -> void:
#	if rect_size.x > 260:
#		rect_size.x = 260
#

func _on_ItemList_item_selected(index: int) -> void:
	var selected = item_list.get_item_text(index).to_lower()
	Events.emit_signal("main_screen_changed", selected)
#	match index:
#		SCREENS.CREW:
#			Events.emit_signal("main_screen_changed", "crew")
#		_:
#			print("invalid index selected")
