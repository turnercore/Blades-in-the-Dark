extends ScrollContainer

export (PackedScene) var ability_scene: PackedScene
onready var ability_list: VBoxContainer = $AbilityContainer

func _ready() -> void:
	Events.connect("crew_loaded", self, "_on_crew_loaded")
	if Globals.crew_playbook: setup(Globals.crew_playbook)

func setup(playbook:CrewPlaybook)->void:

	for ability_name in playbook.abilities.keys():
		var ability = playbook.abilities[ability_name]
		var new_ability: = ability_scene.instance()
		new_ability.name = ability_name
		new_ability.ability = ability_name
		new_ability.effect = ability.effect
		new_ability.claimed = ability.claimed if "claimed" in ability else false
		ability_list.add_child(new_ability)


func _on_crew_loaded(playbook: CrewPlaybook)-> void:
	for child in ability_list.get_children():
		if child is CrewAbility:
			child.queue_free()

	setup(playbook)
