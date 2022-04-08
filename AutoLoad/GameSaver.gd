extends Node

const SAVE_INTERVAL: = 1
const DEFAULT_SRD: = 'res://srd/default_srd.json'
const DEFAULT_SAVE_ID: = "default"
var version = ProjectSettings.get_setting("application/config/version")
var current_save_id: = DEFAULT_SAVE_ID

onready var debug:bool = ProjectSettings.get_setting("debug/settings/debug")
onready var SAVE_FOLDER:String = "res://debug/save" if debug else "user://save"
onready var srd_json: = DEFAULT_SRD

var save_on_interval: = false
var data_changed: = false

signal save_loaded(save_game)
signal crew_loaded(crew_playbook)
signal pc_playbooks_loaded(pc_playbook_array)
signal game_saved


func _ready() -> void:
	var dir: = Directory.new()
	if not dir.dir_exists(SAVE_FOLDER+current_save_id): dir.make_dir_recursive(SAVE_FOLDER+current_save_id)
	if save_on_interval: setup_save_timer()


func setup_save_timer()-> void:
	var save_timer: Timer = Timer.new()
	save_timer.one_shot = false
	save_timer.wait_time = SAVE_INTERVAL
	save_timer.connect("timeout", self, "_on_save_timer_timeout")
	add_child(save_timer)
	save_timer.start()


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
		if save_game.needs_setup:
			print("Setting up Save Game")
			save_game.setup_save(srd_json)
	else:
		save_game = SaveGame.new()
		save_game.setup_save(srd_json)

	emit_signal("save_loaded", save_game)


func load_crew_playbook(save_id:= current_save_id, save_folder:= SAVE_FOLDER)-> void:
	var dir: = Directory.new()
	var crew_playbook: = CrewPlaybook.new()
	var crew_file_path:String = save_folder + "/" + save_id
	if not dir.dir_exists(crew_file_path): dir.make_dir_recursive(crew_file_path)
	var crew_file:String = crew_file_path.plus_file("crew.tres")

	var file: File = File.new()
	if file.file_exists(crew_file_path):
		crew_playbook = ResourceLoader.load(crew_file_path)
		print("loaded crew from file")
	else:
		print(crew_file_path)
		print("no crew file found, creating new crew")

	emit_signal("crew_loaded", crew_playbook)


func load_pc_playbooks(save_id:=current_save_id, save_folder:=SAVE_FOLDER)-> void:
	var pc_playbooks:Dictionary

	var dir: = Directory.new()
	var file_dir:String = save_folder + "/" + save_id + "/players"
	if not dir.dir_exists(file_dir): dir.make_dir_recursive(file_dir)

	var save_files = Globals.list_files_in_directory(file_dir)
	for file in save_files:
		var pc_file_path:String = save_folder + "/" + save_id + "/players".plus_file(file)
		if not "roster" in pc_playbooks: pc_playbooks["roster"] = []
		pc_playbooks["roster"].append(ResourceLoader.load(pc_file_path))

	emit_signal("pc_playbooks_loaded", pc_playbooks)


func load_all(id:= current_save_id, folder:= SAVE_FOLDER)-> void:
	load_save(id, folder)
	load_crew_playbook(id, folder)
	load_pc_playbooks(id, folder)


func save(resource = null, id: = current_save_id, overwrite: = true)->void:
	if not resource:
		print("must have something to save")
		return

	if resource is SaveGame:
		save_game(resource, id, overwrite)
	elif resource is CrewPlaybook:
		save_crew(resource, id, overwrite)
	elif resource is Dictionary or resource is Array or resource is PlayerPlaybook:
		save_pc_playbooks(resource, id, overwrite)


func save_game(save_game:SaveGame, id:= current_save_id, overwrite:=true)-> bool:
	var dir: = Directory.new()

	var save_path:String = SAVE_FOLDER+"/"+id+"/save_data"
	var save_name:String = id.strip_edges().strip_escapes() + "_save_data"
	var save_file:String = save_path.plus_file(save_name+".tres")
	if not dir.dir_exists(save_path): dir.make_dir_recursive(save_path)
	save_game.version = version
	save_game._save_id = id

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


func save_crew(crew_playbook:CrewPlaybook, id:= current_save_id, overwrite:=true) -> bool:
	var dir: = Directory.new()
	var save_path:String = SAVE_FOLDER+"/"+id+"/crew"
	var escaped_name:String = "crew" if not crew_playbook.name else crew_playbook.name.strip_edges().c_escape().strip_escapes()
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


func save_pc_playbooks(pc_playbooks, id:= current_save_id, overwrite: = true)-> bool:
	var playbooks: = []
	var is_an_error: = false
	if pc_playbooks is Playbook:
		playbooks.append(pc_playbooks)
	elif pc_playbooks is Dictionary:
		if "roster" in pc_playbooks:
			for playbook in pc_playbooks.roster:
				if playbook is PlayerPlaybook:
					playbooks.append(playbook)
		else: print("no roster to save")
	elif pc_playbooks is Array:
		playbooks.append_array(pc_playbooks)

	for playbook in playbooks:
		#Save the playbook in folder
		var save_path:String = SAVE_FOLDER+"/"+id+"/pc_playbooks"
		var escaped_name:String = playbook.name.strip_edges().c_escape().strip_escapes()
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


func save_all(resources: Array, id:=current_save_id, overwrite:= true)->void:
	for resource in resources:
		save(resource, id, overwrite)


func _on_data_changed()-> void:
	#Updates whenever the save_game emits the changed signal and queues the save
	data_changed = true


func _on_save_timer_timeout()-> void:
	if data_changed:
		GameData.save_all()
		data_changed = false
