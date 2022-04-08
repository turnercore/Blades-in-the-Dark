extends ScrollContainer

enum AbilityTypes {CREW, PC}

export (AbilityTypes) var type: = AbilityTypes.CREW
export (PackedScene) var ability_scene: PackedScene
onready var ability_list: VBoxContainer = $AbilityContainer

func _ready() -> void:
	match type:
		AbilityTypes.CREW:
			Events.connect("crew_loaded", self, "_on_playbook_loaded")
		AbilityTypes.PC:
			Events.connect("character_changed", self, "_on_playbook_loaded")

func setup(playbook:Playbook)->void:
	for ability_name in playbook.abilities.keys():
		var ability = playbook.abilities[ability_name]
		var new_ability: = ability_scene.instance()
		new_ability.name = ability_name
		new_ability.ability = ability.ability
		new_ability.effect = ability.effect
		new_ability.claimed = ability.claimed if "claimed" in ability else false
		ability_list.add_child(new_ability)


func _on_playbook_loaded(playbook: Playbook)-> void:
	for child in ability_list.get_children():
		if child is AbilityContainer:
			child.queue_free()
	setup(playbook)
