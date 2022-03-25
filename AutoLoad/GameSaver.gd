extends Node

const srd_json = 'res://srd/default_srd.json'
const SaveGame = preload('res://saves/SaveGame.gd')
onready var debug:bool = ProjectSettings.get_setting("debug/settings/debug")
onready var SAVE_FOLDER:String = "res://debug/save" if debug else "user://save"
onready var SAVE_NAME_TEMPLATE:String = "save_%03d.tres"
onready var saved_nodes: = get_tree().get_nodes_in_group("save")
onready var dir: Directory = Directory.new()
var save_game: SaveGame
var game_save_id: int = 100
var data_changed: bool = false
var is_save_game_loaded: bool = false

func _ready() -> void:
	if not dir.dir_exists(SAVE_FOLDER): dir.make_dir_recursive(SAVE_FOLDER)

func save_all():
	save_game.version = ProjectSettings.get_setting("application/config/version")

	for node in saved_nodes:
		node.save(save_game)
		self._save()


func save_node(node: Node):
	#the node passes itself and it's ID to get the save setup
	save_game.version = ProjectSettings.get_setting("application/config/version")
	#This calls save on the node again, just in case.
	node.save(save_game)
	self._save()


func load_all():
	var save_file_path:String = SAVE_FOLDER.plus_file(SAVE_NAME_TEMPLATE % game_save_id)
	var file: File = File.new()
	if file.file_exists(save_file_path):
		save_game = load(save_file_path)
		if save_game.needs_setup: save_game.setup()
	else:
		save_game = SaveGame.new()
		save_game.setup()

	for node in saved_nodes:
		node.load_game(save_game)

	is_save_game_loaded = true


func _save()->void:
	var save_path = SAVE_FOLDER.plus_file(SAVE_NAME_TEMPLATE % game_save_id)
	var error:int = ResourceSaver.save(save_path, save_game)
	if error != OK:
		print("There was an issue writing the save %s to %s" % [game_save_id, save_path])
