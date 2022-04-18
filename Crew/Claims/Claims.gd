extends CenterContainer

var crew_type
#Code to load the database
var _playbook:CrewPlaybook setget _set_playbook
var prison:= false setget _set_prison
var setup_with_playbook:CrewPlaybook
onready var standard_claim_tree: = $VBoxContainer/ClaimTree
onready var prison_claim_tree: = $VBoxContainer/ClaimTreePrison


func _ready() -> void:
	Events.connect("crew_loaded", self, "_on_crew_loaded")
	if GameData.crew_playbook: setup_claims(GameData.crew_playbook)


func setup_claims(playbook: CrewPlaybook) ->void:
	if playbook == setup_with_playbook:
		return

	for child in standard_claim_tree.get_children():
		if child is ClaimTreeConnector: child.deactivate()

	for child in prison_claim_tree.get_children():
		if child is ClaimTreeConnector: child.deactivate()

	for child in standard_claim_tree.get_children():
		if not (child is Claim): continue
		if child.has_method("setup"): child.setup(playbook)

	for child in prison_claim_tree.get_children():
		if not (child is Claim): continue
		if child.has_method("setup"): child.setup(playbook)

	setup_with_playbook = playbook
	_playbook = playbook

func _on_crew_loaded(playbook: CrewPlaybook) -> void:
	setup_claims(playbook)


func _set_playbook(playbook: CrewPlaybook)-> void:
	setup_claims(playbook)


func _on_RecalculateButton_pressed() -> void:
	setup_claims(GameData.crew_playbook)


func _on_PrisonToggle_toggled(button_pressed: bool) -> void:
	self.prison = button_pressed


func _set_prison(value: bool)-> void:
	prison = value
	standard_claim_tree.visible = not value
	prison_claim_tree.visible = value


func _on_Claims_visibility_changed() -> void:
	Tooltip.finish_tooltip()
