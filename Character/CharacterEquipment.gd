extends VBoxContainer

export (PackedScene) var item_scene

func _ready() -> void:
	Events.connect("character_changed", self, "_on_playbook_loaded")

func setup(playbook: Playbook)->void:
	if not "items" in playbook: return

	for key in playbook.items:
		var item = playbook.items[key]
		var new_item = item_scene.instance()
		new_item.item_name = item.name
		new_item.description = item.description
		new_item.item_load = item.load
		new_item.using = item.using
		add_child(new_item)


func _on_playbook_loaded(playbook: Playbook)-> void:
	for child in get_children():
		child.queue_free()
	setup(playbook)
