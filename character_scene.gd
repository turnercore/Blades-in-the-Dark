extends HBoxContainer

var playbook: Playbook setget _set_playbook

func _ready() -> void:
	if playbook: propogate_set_playbook_recursive(self)

func propogate_set_playbook_recursive(node: Node)-> void:
	if "playbook" in node and node != self:
		node.set("playbook", playbook)
	for child in node.get_children():
		propogate_set_playbook_recursive(child)

func _set_playbook(value: Playbook)-> void:
	playbook = value
	propogate_set_playbook_recursive(self)


func _on_Button_pressed() -> void:
	Events.emit_character_changed(playbook)
