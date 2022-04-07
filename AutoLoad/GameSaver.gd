extends Node


const SaveGame = preload('res://saves/SaveGame.gd')
onready var debug:bool = ProjectSettings.get_setting("debug/settings/debug")
onready var SAVE_FOLDER:String = "res://debug/save" if debug else "user://save"
onready var SAVE_NAME_TEMPLATE:String = "save_%s.tres"
onready var dir: Directory = Directory.new()
onready var srd_json: = 'res://srd/default_srd.json'
var save_game: SaveGame = SaveGame.new()
var data_changed: bool = false
var is_save_game_loaded: bool = false
var current_save_id:String = "default save"

signal game_loaded

func _ready() -> void:
	save_game.connect("changed", self, "_on_save_game_changed")
	save_game.version = ProjectSettings.get_setting("application/config/version")
	if not dir.dir_exists(SAVE_FOLDER): dir.make_dir_recursive(SAVE_FOLDER)
	save(current_save_id)


func load_id(id:String):
	id = id.c_escape()
	id = id.strip_escapes()
	id = id.strip_edges()
	current_save_id = id
	var save_file_path:String = SAVE_FOLDER.plus_file(SAVE_NAME_TEMPLATE % id)
	var file: File = File.new()
	if file.file_exists(save_file_path):
		save_game = load(save_file_path)
		print("Save game loaded, id: " + id)
		if save_game.needs_setup:
			print("Setting up Save Game")
			save_game.setup()
	else:
		save_game = SaveGame.new()
		save_game.setup()
	save_game.connect("changed", self, "_on_save_game_changed")
	emit_signal("game_loaded")
	is_save_game_loaded = true


func save(id:String = current_save_id)->void:
	print("saving game " + current_save_id)
	var save_path = SAVE_FOLDER.plus_file(SAVE_NAME_TEMPLATE % id)
	var error:int = ResourceSaver.save(save_path, save_game)
	if error != OK:
		print("There was an issue writing the save %s to %s" % [id, save_path])


func _on_save_game_changed()-> void:
	save(current_save_id)
