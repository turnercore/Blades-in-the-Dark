extends Node

const DEFAULT_SRD: = 'res://srd/default_srd.json'
const DEFAULT_SAVE_ID: = "default"

var save_interval:float
var version = ProjectSettings.get_setting("application/config/version")
var current_save_id: = DEFAULT_SAVE_ID

onready var debug:bool = ProjectSettings.get_setting("debug/settings/debug")
onready var SAVE_FOLDER:String = "res://debug/save" if debug else "user://save"
onready var srd_json: = DEFAULT_SRD

var save_on_interval: = false setget _set_save_on_interval
var data_changed: = false
var save_timer:Timer

signal save_loaded(save_game)
signal crew_loaded(crew_playbook)
signal roster_loaded(pc_playbook_array)
signal game_saved


func _ready() -> void:
	if save_on_interval: setup_save_timer()


func erase(resource:Resource)->void:
	pass

func setup_save_timer()-> void:
	save_timer = Timer.new()
	save_timer.one_shot = false
	save_timer.wait_time = save_interval
	save_timer.connect("timeout", self, "_on_save_timer_timeout")
	add_child(save_timer)
	save_timer.start()

#works
func load_save(id:= current_save_id, folder:= SAVE_FOLDER):
#	if not SAVE_FOLDER: SAVE_FOLDER = "res://debug/save" if debug else "user://save"
	var save_game: SaveGame
	var save_path:String = folder +"/"+id+"/save_data"
	var save_name:String = id.strip_edges().strip_escapes() + "_save_data"
	var save_file:String = save_path.plus_file(save_name+".tres")
	var file: File = File.new()

	if id != current_save_id:
		id = id.c_escape()
		id = id.strip_escapes()
		id = id.strip_edges()
		current_save_id = id

	if file.file_exists(save_file):
		var new_save = ResourceLoader.load(save_file)
		if not new_save:
			print("error loading save")
			return
		if new_save.version != version:
			print("save is incorrect version! May not work")
		save_game = new_save
		print("Save game loaded, id: " + id)
		if not save_game.is_setup:
			print("Setting up Save Game")
			save_game.setup_save(srd_json)
	else:
		save_game = SaveGame.new()
		save_game.setup_save(srd_json)

	emit_signal("save_loaded", save_game)

#works
func load_crew_playbook(save_id:= current_save_id, save_folder:= SAVE_FOLDER)-> void:
	var dir: = Directory.new()
	var crew_playbook: = CrewPlaybook.new()
	var crew_file_path:String = save_folder + "/" + save_id + "/crew"
	if not dir.dir_exists(crew_file_path): dir.make_dir_recursive(crew_file_path)
	var crew_list: Array = Globals.list_files_in_directory(crew_file_path)
	print(crew_list)
	var crew_file_name:String = "crew.tres"
	if crew_list.size() > 1:
		print("multiple crew files found, don't have it set up for that, picking first one sorry not sorry...")
	if crew_list.size() > 0:
		crew_file_name = crew_list.front()
	var crew_file:String = crew_file_path.plus_file(crew_file_name)

	var file: File = File.new()
	if file.file_exists(crew_file):
		crew_playbook = ResourceLoader.load(crew_file)
		print("loaded crew from file")
	else:
		print(crew_file)
		print("no crew file found, creating new crew")

	emit_signal("crew_loaded", crew_playbook)

#works
func load_roster(id:=current_save_id, save_folder:=SAVE_FOLDER)-> void:
	var roster: = []

	var dir: = Directory.new()
	var file_dir:String = save_folder + "/" + id + "/pc_playbooks"
	if not dir.dir_exists(file_dir): dir.make_dir_recursive(file_dir)

	var save_files = Globals.list_files_in_directory(file_dir)
	for file in save_files:
		var pc_file_path:String = file_dir.plus_file(file)
		roster.append(ResourceLoader.load(pc_file_path))

	emit_signal("roster_loaded", roster)

#works
func load_all(id:= current_save_id, folder:= SAVE_FOLDER)-> void:
	self.current_save_id = id
	load_save(id, folder)
	load_crew_playbook(id, folder)
	load_roster(id, folder)

#works
func save(resource = null, id: = current_save_id, overwrite: = true)->void:
	if not resource:
		print("must have something to save")
		return

	if resource is SaveGame:
		save_game(resource, id, overwrite)
	elif resource is CrewPlaybook:
		save_crew(resource, id, overwrite)
	elif resource is Dictionary or resource is Array or resource is PlayerPlaybook:
		save_roster(resource, id, overwrite)

#works
func save_game(save_game:SaveGame, id:= current_save_id, overwrite:=true)-> bool:
	var dir: = Directory.new()

	var save_path:String = SAVE_FOLDER+"/"+id+"/save_data"
	var save_name:String = id.strip_edges().strip_escapes() + "_save_data"
	var save_file:String = save_path.plus_file(save_name+".tres")
	if not dir.dir_exists(save_path): dir.make_dir_recursive(save_path)
	save_game.version = version
	save_game._save_id = id

	#Need to do some data manipulation because godot won't save custom resources
	#Save Clocks
	save_game.clocks.clear()
	for clock in GameData.clocks:
		save_game.clocks.append(clock.package())
	#Save Map Shortcuts
	save_game.map_shortcuts.clear()
	for location in GameData.map_shortcuts:
		save_game.map_shortcuts.append(location.package())
	#Save Map Locations in Map Data
	save_game._map.notes.clear()
	for pos in GameData.map.notes:
		save_game._map.notes[pos] = GameData.map.notes[pos].package()

	#Check for duplicate files if overwrite is false
	if not overwrite:
		var file: = File.new()
		var i:= 0
		while file.file_exists(save_file):
			print(save_file + " already exists, creating new one")
			i += 1
			var new_name = save_name + str(i)
			save_file = save_path.plus_file(new_name+".tres")

	#Save SaveGame Resource
	var error: = ResourceSaver.save(save_file, save_game)
	if error != OK:
		print("There was an issue writing the save %s to %s" % [id, save_path])
		print("error code: " + str(error))
		return false
	else:
		emit_signal("game_saved")
		return true

#works
func save_crew(crew_playbook:CrewPlaybook, id:= current_save_id, overwrite:=true) -> bool:
	var dir: = Directory.new()
	var save_path:String = SAVE_FOLDER+"/"+id+"/crew"
	var escaped_name:String = "crew_"+crew_playbook.id
	var save_file: = save_path.plus_file(escaped_name+".tres")
	if not dir.dir_exists(save_path): dir.make_dir_recursive(save_path)

	#Check for duplicate files if overwrite is false
	if not overwrite:
		var file: = File.new()
		var i:= 0
		while file.file_exists(save_file):
			print(save_file + " already exists, creating new one")
			i += 1
			var new_name = escaped_name + str(i)
			save_file = save_path.plus_file(new_name+".tres")

	var error = ResourceSaver.save(save_file, crew_playbook)
	if error != OK:
		print("There was an issue writing the crew save %s to %s" % [id, save_path])
		print("error code: " + str(error))
		return false
	else:
		return true

#works (I think)
func save_roster(roster, id:= current_save_id, overwrite: = true)-> bool:
	var playbooks: = []
	if roster is Array: playbooks.append_array(roster)
	elif roster is PlayerPlaybook: playbooks.append(roster)
	var is_an_error: = false
	var dir: = Directory.new()
	for playbook in playbooks:
		#Save the playbook in folder
		var save_path:String = SAVE_FOLDER+"/"+id+"/pc_playbooks"
		if not dir.dir_exists(save_path): dir.make_dir_recursive(save_path)
		var escaped_name:String = playbook.id.strip_edges().c_escape().strip_escapes()
		var save_file:String = save_path.plus_file(escaped_name+".tres")

		#Check for duplicate files if overwrite is false
		if not overwrite:
			var file: = File.new()
			var i:= 0
			while file.file_exists(save_file):
				print(save_file + " already exists, creating new one")
				i += 1
				var new_name = escaped_name + str(i)
				save_file = save_path.plus_file(new_name+".tres")

		#Error handling
		var error = ResourceSaver.save(save_file, playbook)
		if error != OK:
			print("There was an issue writing the crew save %s to %s" % [id, save_path])
			print("error code: " + str(error))
			is_an_error = true

	if is_an_error:
		return false
	else:
		return true

#works
func save_all(resources: Array, id:=current_save_id, overwrite:= true)->void:
	for resource in resources:
		print(resource)
		save(resource, id, overwrite)


func _on_data_changed()-> void:
	#Updates whenever the save_game emits the changed signal and queues the save
	data_changed = true


func _on_save_timer_timeout()-> void:
	if data_changed:
		GameData.save_all()
		data_changed = false


func _set_save_on_interval(value:bool)-> void:
	if value:
		if save_timer:
			save_timer.wait_time = save_interval
			save_timer.start(save_interval)
		else: setup_save_timer()
	else:
		if save_timer:
			save_timer.stop()
