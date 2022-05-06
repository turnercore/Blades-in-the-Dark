extends VBoxContainer

export (NodePath) onready var coin_container = get_node(coin_container) as Control


func _process(_delta: float) -> void:
	if visible:
		coin_container.visible = true
		set_process(false)
