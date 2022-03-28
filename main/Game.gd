extends VSplitContainer

var saved_chat_offset:float = 0

func _ready() -> void:
	connect_to_events()

	for child in $MainView/MainScreen.get_children():
		child.visible = false
		$MainView/Controls/ItemList.add_item(child.name)

	$MainView/MainScreen.get_child(0).visible= true


func connect_to_events()->void:
	Events.connect("chat_hidden", self, "_on_chat_hidden")
	Events.connect("chat_unhidden", self, "_on_chat_unhidden")


func _on_chat_unhidden()->void:
	self.split_offset = saved_chat_offset


func _on_chat_hidden()->void:
	saved_chat_offset = self.split_offset
	self.split_offset = 100000

