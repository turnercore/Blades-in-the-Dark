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


func erase(file:String)->void:
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

func save_resource(file_path:String, resource:Resource)-> void:
	pass

#works
func load_all(id:= current_save_id, folder:= SAVE_FOLDER)-> void:
	self.current_save_id = id
	load_save(id, folder)

#works
func save(save_game:SaveGame, id:= current_save_id, overwrite:=true)-> bool:
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
