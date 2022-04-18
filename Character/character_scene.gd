extends HBoxContainer

var playbook: Playbook setget _set_playbook

signal pressed

func _ready() -> void:
	if playbook: propagate_set_playbook_recursive(self)

func propagate_set_playbook_recursive(node: Node)-> void:
	if "playbook" in node and node != self:
		node.set("playbook", playbook)
	for child in node.get_children():
		propagate_set_playbook_recursive(child)

func _set_playbook(value: Playbook)-> void:
	playbook = value
	propagate_set_playbook_recursive(self)


func _on_Button_pressed() -> void:
	GameData.active_pc = playbook
