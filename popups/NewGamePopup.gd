extends PopupScreen

onready var crew_button: = $MarginContainer/PopupPanel/VBoxContainer/CreateNewCrewButton
var srd_path: = GameData.DEFAULT_SRD
var save_id:String
var new_save = SaveGame.new()

func _ready() -> void:
	crew_button.on_start_screen = true
	new_save.connect("id_changed", GameSaver, "_on_save_id_changed")


func _on_CreateNewCrewButton_pressed() -> void:
	new_save.setup(srd_path)
	new_save.id = save_id
	GameData.create_save(new_save)
	hide()


func _on_TextEdit_text_changed(new_text: String) -> void:
	self.save_id = new_text


func _on_CancelButton_pressed() -> void:
	new_save.disconnect("id_changed", GameSaver, "_on_save_id_changed")
	hide()
