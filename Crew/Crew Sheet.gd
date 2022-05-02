extends Container

var resource: NetworkedResource setget _set_crew_resource
var crew_loaded: bool = false
export (PackedScene) var crew_setup_sceen

const ID: String = "crew"

#Not sure if this is needed
enum tabs {
	CREW_SHEET,
	LAIR,
	SKILL_TREE,
	NOTES
}


func _ready() -> void:
#	GameSaver.connect("crew_loaded", self, "_on_crew_loaded")
#	if GameData.crew_playbook: self._playbook = GameData.crew_playbook
	propagate_set_editable(self, false)

#
#func _on_crew_loaded(playbook:CrewPlaybook)-> void:
#	_playbook = playbook
#	Globals.propagate_set_playbook_recursive(self, playbook, self)
##

func show_crew_setup()->void:
	print("showing crew setup")
	var crew_setup_popup = crew_setup_sceen.instance()
	Events.emit_signal("popup", crew_setup_popup)


func _set_crew_resource(playbook:NetworkedResource)-> void:
	resource = playbook
	Globals.propagate_set_property_recursive(self, "resource", playbook)


func propagate_set_editable(parent: Node, editable: bool = false)->void:
	#set disabled to the opposite of the passed editable variable
	var disabled = not editable
	for child in parent.get_children():
		if child.is_in_group("skip_disable"):
			continue
		if child is Container:
			propagate_set_editable(child, editable)
		else:
			if "editable" in child:
				child.editable = editable
			if "disabled" in child:
				child.disabled = disabled
			if "readonly" in child:
				child.readonly = disabled
			if "flat" in child:
				child.flat = disabled
			if child is SaveableField and child is LineEdit:
				child.visible = editable
			if child is SaveableField and child is Label:
				child.visible = not editable


func _on_CheckButton_toggled(button_pressed: bool) -> void:
	propagate_set_editable(self, button_pressed)


func _on_LairPicture_gui_input(event: InputEvent) -> void:
	#I think there is probably a better way to do this...
	if event.is_action_pressed("left_click"):
		get_parent().current_tab = tabs.LAIR

