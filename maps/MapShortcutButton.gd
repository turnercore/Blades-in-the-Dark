extends Button


var pos:Vector2
var location:NetworkedResource
var description:String = ""



func _on_ShortcutButton_mouse_entered() -> void:
	Tooltip.display_tooltip(location.get_property("location_name"), location.get_property("description"))


func _on_ShortcutButton_mouse_exited() -> void:
	Tooltip.finish_tooltip(location.get_property("location_name"), location.get_property("description"))

