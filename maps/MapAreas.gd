extends Node2D


func _ready() -> void:
	for child in get_children():
		if child is Area2D:
			child.connect("area_entered", self, "_on_area_entered", [child])
			child.connect("area_exited", self, "_on_area_exited", [child])


func _on_area_entered(area: Area2D, region: Area2D) -> void:
	if area is Cursor and not area.is_remote:
		region.visible = true


func _on_area_exited(area: Area2D, region: Area2D) -> void:
	if area is Cursor and not area.is_remote:
		region.visible = false
