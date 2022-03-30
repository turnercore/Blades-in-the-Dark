extends TabContainer



func _process(delta: float) -> void:
	set_visible_recursive(self, visible)

func set_visible_recursive(node:Node, value: bool)->void:
	if "visible" in node:
		node.visible = value
	for child in node.get_children():
		set_visible_recursive(child, value)
