extends Popup

onready var saves_list: = $LoadContainer/PanelContainer/ScrollContainer/SavesList
onready var cancel_button: = $LoadContainer/PanelContainer/ScrollContainer/SavesList/CancelButton
var on_start_screen:= false

func _ready()->void:
	var dir:= Directory.new()
	var folders:Array = Globals.list_folders_in_directory(GameSaver.SAVE_FOLDER)

	for folder in folders:
		if folder.begins_with("chat"): continue
		if folder.ends_with(".tres"): continue

		dir.open(folder)
		var button: = Button.new()
		var save_id:String = folder
		var button_text: = save_id.capitalize()
		button.text = button_text
		button.connect("pressed", self, "_button_clicked", [save_id])
		saves_list.add_child(button)
		saves_list.move_child(cancel_button, saves_list.get_child_count())


func _button_clicked(id: String)-> void:
	GameSaver.load_all(id)
	print("load game id: " + id)
	Events.emit_signal("popup_finished")
	if on_start_screen:
		get_tree().change_scene_to(Globals.GAME_SCENE)
	else:
		queue_free()


func _on_LoadScreen_popup_hide() -> void:
	Events.emit_signal("popup_finished")
	queue_free()


func _on_CancelButton_pressed() -> void:
	Events.emit_signal("popup_finished")
	queue_free()
