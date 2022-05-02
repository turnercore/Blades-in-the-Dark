extends DragableWindow

var title:=""
var description:=""
export(NodePath) onready var title_label = get_node(title_label)
export(NodePath) onready var info_label = get_node(info_label)

func _ready() -> void:
	title_label.text = title
	info_label.text = description

func _on_CloseButton_pressed() -> void:
	self.hide()
