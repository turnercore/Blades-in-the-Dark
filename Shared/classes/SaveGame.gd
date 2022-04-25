class_name SaveGame
extends Resource

const DEFAULT_SRD: = "res://srd/default_srd.json"
var debug:bool = ProjectSettings.get_setting("debug/settings/debug")
var srd_data_path: = DEFAULT_SRD
var srd_data
export (String) var _save_id: = "default"
export (String) var _save_folder: = "res://debug/save" if debug else "user://save"
export (String) var version: String = ''
export (Dictionary) var _map: = {} setget _set_map


export (Array) var maps:=[]


export (Dictionary) var clocks  setget _set_clocks

var needs_setup:bool = true


func setup_save(srd_json_path: String = "")->void:
	if srd_json_path == "":
		srd_json_path = DEFAULT_SRD

	needs_setup = false

	var file = File.new()
	if not file.file_exists(srd_json_path):
		print("unable to find file: " + srd_json_path)
	else:
		file.open(srd_json_path, File.READ)
		srd_data = parse_json(file.get_as_text())
		file.close()
	setup_srd_maps()


func setup_srd_maps()-> void:
	#Set the srd maps into the maps array
	for srd_map_name in srd_data.default_maps:
		var srd_map:Dictionary = srd_data.default_maps[srd_map_name]
		var new_map:= {}
		new_map["map_name"] = srd_map.name

		#Check to see if the map already exists so we don't overwrite the data
		var map_exists: = false
		var i: = 0
		for map in maps:
			if map.map_name == srd_map.name:
				map_exists = true
				break
			else:
				i += 1

		new_map["map_index"] = i if map_exists else maps.size()
		if map_exists and "description" in maps[i]:
			new_map["description"] = maps[i].description if map_exists else srd_map.description
		new_map["image"] = maps[i].image if map_exists else srd_map.image
		new_map["notes"] = maps[i].notes if map_exists else {}
		new_map["srd_notes"] = maps[i].srd_notes if map_exists else {}

		if map_exists:
			for property in maps[i]:
				if not property in new_map:
					new_map[property] = maps[i][property]
		else:
			for property in srd_map:
				if not property in new_map:
					new_map[property] = srd_map[property]

		for pos in srd_data.default_locations:
			var vec_pos:Vector2
			if pos is String:
				vec_pos = Globals.str_to_vec2(pos)
			else:
				vec_pos = pos
			if new_map.map_name == srd_data.default_locations[pos].map:
				new_map.srd_notes[vec_pos] = srd_data.default_locations[pos]

		if map_exists: maps[i] = new_map
		else: maps.append(new_map)

	if _map.empty(): _map = maps[0]


func _set_clocks(value:Dictionary)-> void:
	clocks = value
	emit_changed()


func _set_map(value:Dictionary)-> void:
	_map = value
	emit_changed()
