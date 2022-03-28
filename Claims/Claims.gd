extends CenterContainer

var crew_type
#Code to load the database

func _ready() -> void:
	Events.connect("crew_loaded", self, "_on_crew_loaded")
	if Globals.crew_playbook: setup_claims(Globals.crew_playbook)


func setup_claims(playbook: CrewPlaybook) ->void:
	for child in $VBoxContainer/ClaimTree.get_children():
		if child is ClaimTreeConnector: child.deactivate()

	for child in $VBoxContainer/ClaimTree.get_children():
		if not (child is ClaimCell): continue
		if child.has_method("setup"): child.setup(playbook)

func _on_crew_loaded(playbook: CrewPlaybook) -> void:
	setup_claims(playbook)


func _on_RecalculateButton_pressed() -> void:
	setup_claims(Globals.crew_playbook)
