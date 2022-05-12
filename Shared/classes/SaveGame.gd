class_name SaveGame
extends Resource

const DEFAULT_SRD: = "res://srd/bitd_srd.json"

export (Dictionary) var settings:Dictionary

var debug:bool = ProjectSettings.get_setting("debug/settings/debug")
var srd_file_path: = DEFAULT_SRD
export (Dictionary) var srd
export (String) var id
var _save_folder: = "res://debug/save" if debug else "user://save"
export (String) var version: String = ''
export (String) var map:String setget _set_map
export (Dictionary) var maps: = {}
export (Dictionary) var clocks: = {}  setget _set_clocks
export (Array) var map_shortcuts: = [].duplicate()
export (Dictionary) var contacts: = {}
export (Dictionary) var cohorts: = {}
export (Dictionary) var factions: = {}
export (Dictionary) var pc_playbooks: = {}
export (Dictionary) var crew_playbook: = {}
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
	if not "maps" in srd:
		print("Maps not found in srd")
	if not "locations" in srd:
		print("locations not found in srd")
	if not "map_regions" in srd:
		print("regions not found in srd")

	srd_maps = srd.maps.duplicate(true)

	#Set the srd maps into the maps array
	for key in srd_maps:
		if maps.has(key): continue

		var srd_map = srd_maps[key]
		var new_map = srd_map.duplicate(true)

		if not "id" in new_map:
			new_map["id"] = Globals.generate_id(6)
			while maps.has(new_map.id):
				new_map.id = Globals.generate_id(6)

		new_map["locations"] = {}
		var locations:Array = srd.locations.duplicate(true)
		for location in locations:
			var vec2 = location.pos
			new_map.locations[vec2] = location

		new_map["regions"] = {}
		var regions:Array = srd.map_regions.duplicate(true)
		for region in regions:
			var vec2 = region.pos
			new_map.regions[vec2] = region

		maps[new_map.id] = new_map


func _set_clocks(value:Dictionary)-> void:
	clocks = value
	if is_setup: emit_changed()


func _set_map(value:String)-> void:
	map = value
	if is_setup: emit_changed()
