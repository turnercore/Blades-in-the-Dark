extends Popup

onready var saves_list: = $LoadContainer/SavesList
onready var SAVE_FOLDER: = GameSaver.SAVE_FOLDER
var save_files: = []


func _ready()->void:
	save_files = list_files_in_directory(SAVE_FOLDER)
	for file in save_files:
		var button: = Button.new()
		var file_parts:PoolStringArray = file.split("_", false, 2)
		var file_id:String = file_parts[1].replace(".tres", "")
		button.text = file_id
		button.connect("pressed", self, "_button_clicked", [file_id])
		saves_list.add_child(button)


func _button_clicked(id: String)-> void:
	GameSaver.load_id(id)
	Events.emit_signal("popup_finished")
	queue_free()


func list_files_in_directory(path):
	var files: = []
	var dir: = Directory.new()
	dir.open(path)
	dir.list_dir_begin()

	while true:
		var file = dir.get_next()
		if file == "": break
		elif file.ends_with(".tres") and not file.begins_with("."):
			files.append(file)

	dir.list_dir_end()
	return files


func _on_LoadScreen_popup_hide() -> void:
	Events.emit_signal("popup_finished")
	queue_free()
