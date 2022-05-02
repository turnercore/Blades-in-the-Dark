extends CanvasLayer


# Declare member variables here. Examples:
# var a: int = 2
# var b: String = "text"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Events.connect("tooltip_frozen", self, "_on_tooltip_frozen")


func _on_tooltip_frozen(tooltip:DragableWindow)-> void:
	add_child(tooltip)
	tooltip.show()
