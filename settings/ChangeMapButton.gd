extends Button

export (NodePath) onready var file_dialog = get_node(file_dialog) as FileDialog


func _on_ChangeMapButton_pressed() -> void:
	file_dialog.popup()


func _on_FileDialog_file_selected(path: String) -> void:
	print(path)
	Events.emit_map_created(path)
