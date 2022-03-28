extends Node


const SaveGame = preload('res://saves/SaveGame.gd')
onready var debug:bool = ProjectSettings.get_setting("debug/settings/debug")
onready var SAVE_FOLDER:String = "res://debug/save" if debug else "user://save"
onready var SAVE_NAME_TEMPLATE:String = "save_%s.tres"
onready var saved_nodes: = get_tree().get_nodes_in_group("save")
onready var dir: Directory = Directory.new()
onready var srd_json = Globals.SRD
var save_game: SaveGame = SaveGame.new()
var data_changed: bool = false
var is_save_game_loaded: bool = false
var current_save_id:String = "unset"

func _ready() -> void:
	if not dir.dir_exists(SAVE_FOLDER): dir.make_dir_recursive(SAVE_FOLDER)

func save_all(id:String = current_save_id):
	save_game.version = ProjectSettings.get_setting("application/config/version")

	for node in saved_nodes:
		node.save(save_game)
		self._save(current_save_id)


func save_node(node: Node):
	#the node passes itself and it's ID to get the save setup
	save_game.version = ProjectSettings.get_setting("application/config/version")
	#This calls save on the node again, just in case.
	node.save(save_game)
	self._save(current_save_id)




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
		if save_game.needs_setup: save_game.setup()
	else:
		save_game = SaveGame.new()
		save_game.setup()

	for node in saved_nodes:
		node.load_game(save_game)

	is_save_game_loaded = true


func _save(id:String = current_save_id)->void:
	var save_path = SAVE_FOLDER.plus_file(SAVE_NAME_TEMPLATE % id)
	var error:int = ResourceSaver.save(save_path, save_game)
	if error != OK:
		print("There was an issue writing the save %s to %s" % [id, save_path])
