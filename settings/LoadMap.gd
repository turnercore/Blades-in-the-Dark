extends Button

const MAP_ICON:= preload("res://settings/old_map_icon.tres")

onready var map_chooser: = $MapChooser

func _ready() -> void:
	add_title_item()

func _on_MapChooser_index_pressed(index: int) -> void:
	#Index 0 is being used for a title
	print(index)
	Events.emit_map_changed(index - 1)

func add_title_item()-> void:
	map_chooser.add_separator("Choose a map")


func _on_LoadMap_pressed() -> void:
	map_chooser.clear()
	add_title_item()
	for map in GameData.save_game.maps:
		map_chooser.add_icon_item(MAP_ICON, map.name)
	map_chooser.popup()
