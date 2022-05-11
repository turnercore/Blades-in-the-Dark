class_name SaveGame
extends Resource

const DEFAULT_SRD: = "res://srd/bitd_srd.json"

var username:String
var user_color:String
var settings:Dictionary

var debug:bool = ProjectSettings.get_setting("debug/settings/debug")
var srd_file_path: = DEFAULT_SRD
export (Dictionary) var srd
export (String) var id
var _save_folder: = "res://debug/save" if debug else "user://save"
export (String) var version: String = ''
export (Dictionary) var map: = {} setget _set_map, _get_map
export (Array) var maps: = [].duplicate()
export (Array) var clocks: = [].duplicate()  setget _set_clocks
export (Array) var map_shortcuts: = [].duplicate()
export (Dictionary) var contacts: = {}
export (Dictionary) var factions: = {}
export (bool) var is_setup: = false
export (Array) var pc_playbooks: = [].duplicate()
export (Dictionary) var crew_playbook: = {}
var recently_deleted:Array = [].duplicate()

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
		print("ERROR IN LOAD SRD SAVEGAME")
		print("unable to find file: " + file_path)
	else:
		file.open(file_path, File.READ)
		data = parse_json(file.get_as_text())
		file.close()
	return data


func setup_maps_from_srd(new_srd:Dictionary)-> void:
	srd = new_srd
	var srd_maps
	if "default_maps" in srd:
		srd_maps = srd.default_maps.duplicate(true)
	if "maps" in srd:
		srd_maps = srd.maps.duplicate(true)

	#Set the srd maps into the maps array
	for key in srd_maps:
		var map_exists_already: = false
		for loaded_map in maps:
			if "name" in loaded_map and loaded_map.name == key:
				map_exists_already = true
		if map_exists_already: continue
		var srd_map = srd_maps[key]
		var new_map = srd_map.duplicate(true)

		new_map["index"] = maps.size()
		new_map["locations"] = {}
		var locations
		if "locations" in srd:
			locations = srd.locations.duplicate(true)
		elif "default_locations" in srd:
			locations = srd.default_locations.duplicate(true)
		for location in locations:
			var vec2 = location.pos
			if vec2 is String:
				vec2 = str2var(vec2)
			new_map.locations[vec2] = location
			if new_map.locations[vec2].pos is String:
				new_map.locations[vec2].pos = str2var(new_map.locations[vec2].pos)
		maps.append(new_map)


func _set_clocks(value:Array)-> void:
	clocks = value
	if is_setup: emit_changed()


func _set_map(value:Dictionary)-> void:
	map = value

	if is_setup: emit_changed()

func _get_map()-> Dictionary:
	if map.empty() and not maps.empty():
		self.map = maps[0]

	return map
