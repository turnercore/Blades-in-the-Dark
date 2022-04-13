extends Control

var buttons:Dictionary


func _ready() -> void:
	for child in $MarginContainer/Panel/VBoxContainer.get_children():
		buttons[child.name] = child

	Events.connect("character_selected", self, "_on_character_selected")

	if not GameData.active_pc:
		buttons.CharacterButton.disabled = true
		buttons.CharacterButton.visible = false


func _on_character_selected(_playbook)->void:
	buttons.CharacterButton.disabled = false
	buttons.CharacterButton.visible = true


func _on_CrewSheetButton_pressed() -> void:
	Events.popup("crew")


func _on_RosterButton_pressed() -> void:
	Events.popup("roster")


func _on_ClocksButton_pressed() -> void:
	Events.popup("clocks")


func _on_CharacterButton_pressed() -> void:
	Events.popup("character")
