class_name SaveGame
extends Resource

const DEFAULT_SRD: = "res://srd/default_srd.json"

var srd_data_path: = DEFAULT_SRD
var srd_data
export (String) var _save_id: = "default"
export (String) var _save_folder: = "res://debug/save"
export (String) var version: String = ''
export (Dictionary) var map: = {} setget _set_map


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

	if map.empty(): map = maps[0]


func _set_clocks(value:Dictionary)-> void:
	clocks = value
	emit_changed()


func _set_map(value:Dictionary)-> void:
	map = value
	emit_changed()


#	load_crew_playbook(save_id, save_folder)
#	load_pc_playbooks(save_id, save_folder)

#	for playbook in pc_playbooks:
#		if not playbook is PlayerPlaybook: continue
#		if playbook.has_signal("property_changed"):
#			playbook.connect("property_changed", self, "_on_playbook_update")
#
#	if crew_playbook.has_signal("property_changed"):
#		crew_playbook.connect("property_changed", self, "_on_playbook_update")



#func load_crew_playbook(save_id:String, save_folder:String)-> void:
#	var loaded_crew_playbook: = CrewPlaybook.new()
#	var crew_file_path:String = save_folder + "/" + save_id.plus_file("crew.tres")
#	print(crew_file_path + "crew file path")
#	var file: File = File.new()
#
#	if file.file_exists(crew_file_path):
#		loaded_crew_playbook = ResourceLoader.load(crew_file_path)
#		print("loaded crew from file")
#	else:
#		print(crew_file_path)
#		print("no crew file found, creating new crew")
#
#	crew_playbook = loaded_crew_playbook


#
#func load_pc_playbooks(save_id:String, save_folder:String)-> void:
#	var dir: = Directory.new()
#	pc_playbooks.clear()
#	var file_dir:String = save_folder + "/" + save_id + "/players"
#	if not dir.dir_exists(file_dir): dir.make_dir_recursive(file_dir)
#	var save_files = list_files_in_directory(file_dir)
#	for file in save_files:
#		var pc_file_path:String = save_folder + "/" + save_id + "/players".plus_file(file)
#		pc_playbooks.append(ResourceLoader.load(pc_file_path))


#func list_files_in_directory(path):
#	var files: = []
#	var dir: = Directory.new()
#	dir.open(path)
#	dir.list_dir_begin()
#
#	while true:
#		var file = dir.get_next()
#		if file == "": break
#		elif file.ends_with(".tres") and not file.begins_with(".") and not file.ends_with("crew.tres"):
#			files.append(file)
#
#	dir.list_dir_end()
#	return files


#
#func set_crew_playbook(playbook: CrewPlaybook)-> void:
#	crew_playbook = playbook
#	emit_changed()
#
#
#func add_pc_playbook(playbook:Playbook)-> void:
#	pc_playbooks.append(playbook)
#	emit_changed()
#
#
#func remove_pc_playbook(playbook:Playbook)-> void:
#	if playbook in pc_playbooks:
#		pc_playbooks.erase(playbook)
#		emit_changed()
#
#
#func _set_crew_playbook(playbook:CrewPlaybook)->void:
#	crew_playbook = playbook
#	emit_changed()
#
#
#func _on_playbook_update(_property_changed)-> void:
#	emit_changed()
