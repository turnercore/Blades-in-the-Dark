extends CanvasLayer


func _ready() -> void:
	Events.connect("tooltip_container_transfered", self, "_on_tooltip_container_transfered")
	Events.emit_signal("popup_layer_ready")

func _on_tooltip_container_transfered(tooltip_container:Node)-> void:
	add_child(tooltip_container)
