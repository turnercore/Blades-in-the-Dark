extends Popup

var save_game_id: = "default" setget _set_id
onready var crew_button: = $MarginContainer/PopupPanel/VBoxContainer/CreateNewCrewButton


func _ready() -> void:
	crew_button.on_start_screen = true


func _on_CreateNewCrewButton_pressed() -> void:
	var new_save = SaveGame.new()
	GameSaver.current_save_id = save_game_id
	GameData.save_game = new_save
	#This function was finishing before the other function started yielding
	#Waiting for the idle frame seems to fix it
	yield(get_tree(), "idle_frame")
	GameSaver.emit_signal("save_loaded", new_save)
	GameSaver.save(new_save, save_game_id, false)



func _on_TextEdit_text_changed(new_text: String) -> void:
	self.save_game_id = new_text


func _set_id(value:String)-> void:
	var new_id = value.strip_edges().c_escape().strip_escapes()
	save_game_id = new_id


func _on_NewGamePopup_popup_hide() -> void:
	Events.emit_signal("popup_finished")
	queue_free()


func _on_CancelButton_pressed() -> void:
	Events.emit_signal("popup_finished")
	queue_free()
