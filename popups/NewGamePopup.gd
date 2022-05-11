extends PopupScreen

var save_game_id: = "default" setget _set_id
onready var crew_button: = $MarginContainer/PopupPanel/VBoxContainer/CreateNewCrewButton
var srd_path: = GameData.DEFAULT_SRD

func _ready() -> void:
	crew_button.on_start_screen = true


func _on_CreateNewCrewButton_pressed() -> void:
	var new_save = SaveGame.new()
	GameSaver.current_save_id = save_game_id
	new_save.id = save_game_id
	new_save.setup(srd_path)
	GameData.create_save(new_save)
	#This function was finishing before the other function started yielding
	#Waiting for the idle frame seems to fix it
	yield(get_tree(), "idle_frame")
	GameData.save_game()
	hide()


func _on_TextEdit_text_changed(new_text: String) -> void:
	self.save_game_id = new_text


func _set_id(value:String)-> void:
	var new_id = value.strip_edges().c_escape().strip_escapes()
	save_game_id = new_id


func _on_CancelButton_pressed() -> void:
	hide()
