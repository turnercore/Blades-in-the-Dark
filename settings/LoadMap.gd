extends Button

const MAP_ICON:= preload("res://settings/old_map_icon.tres")

onready var map_chooser: = $MapChooser
var maps: = {}

func _ready() -> void:
	add_title_item()

func _on_MapChooser_index_pressed(index: int) -> void:
	#Index 0 is being used for a title
	var id:int = map_chooser.get_item_id(index)
	var map_id:String = maps[id]
	Events.emit_map_changed(map_id)

func add_title_item()-> void:
	map_chooser.add_separator("Choose a map")


func _on_LoadMap_pressed() -> void:
	map_chooser.clear()
	add_title_item()
	var i:int = 100
	for id in GameData.maps:
		var map:Dictionary = GameData.maps[id]
		map_chooser.add_icon_item(MAP_ICON, map.name, i)
		maps[i] = id
	map_chooser.popup_centered()
