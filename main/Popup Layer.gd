extends CanvasLayer

onready var overlay: = $OverlayBackground

func _ready() -> void:
	overlay.visible = false
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Globals.popup_layer = self
	Events.connect("popup", self, "_on_popup")
	Events.connect("popup_finished", self, "_on_popup_finished")


func _on_popup(popup: Node)-> void:
	$OverlayBackground.visible = true
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(popup)
	if popup is Popup:
		popup.popup()

func _on_popup_finished()-> void:
	overlay.visible = false
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
