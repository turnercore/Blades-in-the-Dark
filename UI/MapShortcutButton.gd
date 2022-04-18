extends Button


var pos:Vector2
var location:String
var description:String = ""



func _on_ShortcutButton_mouse_entered() -> void:
	Tooltip.display_tooltip(location, description)


func _on_ShortcutButton_mouse_exited() -> void:
	Tooltip.finish_tooltip(location, description)

