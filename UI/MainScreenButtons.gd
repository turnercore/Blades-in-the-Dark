extends Control

var buttons:Dictionary
onready var hide_button: = $MarginContainer/Panel/VBoxContainer/Hide


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


func _on_GMButton_pressed() -> void:
	Events.poopup("GM")


func _on_srdButton_pressed()-> void:
	Events.popup("srd")


func _on_Hide_toggled(hidden: bool) -> void:
	for button in buttons:
		if buttons[button] == hide_button:
			buttons[button].text = "Hide" if not hidden else "Show"
		else:
			buttons[button].visible = not hidden
			buttons[button].disabled =  hidden

	if not hidden:
		if not GameData.active_pc:
			buttons.CharacterButton.disabled = true
			buttons.CharacterButton.visible = false

	modulate.a = 0.5 if hidden else 1


func _on_DiceRollerButton_pressed() -> void:
	Events.popup("dice")
