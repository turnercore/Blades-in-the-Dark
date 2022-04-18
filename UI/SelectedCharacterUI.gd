extends Control


export (Resource) var playbook setget _set_playbook


func _ready() -> void:
	Events.connect("character_selected", self, "_on_character_selected")
	if playbook:
		self.playbook = playbook
	elif not playbook:
		if GameData.active_pc:
			self.playbook = GameData.active_pc
		else:
			visible = false


func _on_character_selected(pc_playbook:PlayerPlaybook)->void:
	print("character selected !! Updating UI")
	self.playbook = pc_playbook
	visible = true


func _set_playbook(pc_playbook:PlayerPlaybook)-> void:
	playbook = pc_playbook
	Globals.propagate_set_playbook_recursive(self, playbook, self)


func _on_CharacterImage_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("left_click"):
		Events.popup("character")


func _on_HideButton_toggled(hidden: bool) -> void:
	$PanelContainer/VBoxContainer.visible = not hidden
	$PanelContainer.self_modulate.a = 0 if hidden else 0.9
	$PanelContainer/HideButton.text = "Show Active Chartacter" if hidden else "Hide"
