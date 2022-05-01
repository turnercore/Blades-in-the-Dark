class_name ChatSaver
extends Node
var debug:bool
var SAVE_FOLDER:String
var SAVE_NAME_TEMPLATE:String
var dir: Directory
var chat_log: ChatLog

func init() -> void:
	debug = ProjectSettings.get_setting("debug/settings/debug")
	SAVE_FOLDER = "res://debug/save/chatlogs" if debug else "user://save/chatlogs"
	SAVE_NAME_TEMPLATE = "chatlog_%03d.tres"
	dir = Directory.new()
	chat_log = ChatLog.new()
	if not dir.dir_exists(SAVE_FOLDER): dir.make_dir_recursive(SAVE_FOLDER)


func load_chat(id:int):
	var save_file_path:String = SAVE_FOLDER.plus_file(SAVE_NAME_TEMPLATE % id)
	var file: File = File.new()
	if debug: assert (file.file_exists(save_file_path))
	chat_log = load(save_file_path)


func save_chat(id: int)->void:
	chat_log.version = ProjectSettings.get_setting("application/config/version")
	var save_path = SAVE_FOLDER.plus_file(SAVE_NAME_TEMPLATE % id)
	var error:int = ResourceSaver.save(save_path, chat_log)
	if error != OK:
		print("There was an issue writing the save %s to %s" % [id, save_path])
