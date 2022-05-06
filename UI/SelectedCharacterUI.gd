extends Control


var resource setget _set_resource


func _ready() -> void:
	Events.connect("character_selected", self, "_on_character_selected")
	if resource:
		self.resource = resource
	elif not resource:
		if GameData.active_pc:
			self.resource = GameData.active_pc
		else:
			visible = false


func _on_character_selected(pc_playbook:NetworkedResource)->void:
	print("character selected !! Updating UI")
	self.resource = pc_playbook
	visible = true


func _set_resource(pc_playbook:NetworkedResource)-> void:
	resource = pc_playbook
	Globals.propagate_set_property_recursive(self, "resource", pc_playbook)


func _on_CharacterImage_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("left_click"):
		Events.popup("character")


func _on_HideButton_toggled(hidden: bool) -> void:
	$PanelContainer/VBoxContainer.visible = not hidden
	$PanelContainer.self_modulate.a = 0 if hidden else 0.9
	$PanelContainer/HideButton.text = "Show Active Chartacter" if hidden else "Hide"


func _on_PanelContainer_mouse_entered() -> void:
	Events.emit_signal("mouse_locked", self)


func _on_PanelContainer_mouse_exited() -> void:
	Events.emit_signal("mouse_unlocked", self)
