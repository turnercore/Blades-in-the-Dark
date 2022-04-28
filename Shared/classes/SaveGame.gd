class_name SaveGame
extends Resource

const DEFAULT_SRD: = "res://srd/default_srd.json"

var username:String
var user_color:String
var settings:Dictionary

var debug:bool = ProjectSettings.get_setting("debug/settings/debug")
var srd_file_path: = DEFAULT_SRD
export (Dictionary) var srd
export (String) var _save_id
var _save_folder: = "res://debug/save" if debug else "user://save"
export (String) var version: String = ''
export (Dictionary) var _map setget _set_map
export (Array) var maps
export (Array) var clocks  setget _set_clocks
export (Array) var map_shortcuts
export (bool) var is_setup: = false


func setup(provided_srd_file_path: String = "")->void:
	if provided_srd_file_path:
		srd_file_path = provided_srd_file_path
	if srd.empty():
		srd = load_srd(srd_file_path)
	if maps.empty():
		setup_maps_from_srd(srd)
	is_setup = true


func load_srd(file_path:String)-> Dictionary:
	var data:={}
	var file = File.new()
	if not file.file_exists(file_path):
		print("unable to find file: " + file_path)
	else:
		file.open(file_path, File.READ)
		data = parse_json(file.get_as_text())
		file.close()
	return data


func setup_maps_from_srd(srd:Dictionary)-> void:
	var srd_maps
	if "default_maps" in srd:
		srd_maps = srd.default_maps
	if "maps" in srd:
		srd_maps = srd.maps

	#Set the srd maps into the maps array
	for key in srd_maps:
		var map_exists_already: = false
		for loaded_map in maps:
			if "name" in loaded_map and loaded_map.name == key:
				map_exists_already = true
		if map_exists_already: continue
		var new_map:= {}
		var srd_map = srd_maps[key]

		for property in srd_maps[key]:
			new_map[property] = srd_maps[key][property]

		new_map["map_index"] = maps.size()
		new_map["notes"] = {}
		var locations
		if "locations" in srd:
			locations = srd.locations
		elif "default_locations" in srd:
			locations = srd.default_locations
		for vec2 in locations:
			var location = locations[vec2]
			if vec2 is String:
				vec2 = Globals.str_to_vec2(vec2)
			new_map.notes[vec2] = location
			if new_map.notes[vec2].pos is String:
				new_map.notes[vec2].pos = Globals.str_to_vec2(new_map.notes[vec2].pos)
		maps.append(new_map)


func _set_clocks(value:Array)-> void:
	clocks = value
	if is_setup: emit_changed()


func _set_map(value:Dictionary)-> void:
	_map = value
	if is_setup: emit_changed()
