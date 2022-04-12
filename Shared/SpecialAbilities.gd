extends ScrollContainer

#enum AbilityTypes {CREW, PC}

var _playbook:Playbook setget _on_playbook_loaded
#export (AbilityTypes) var type: = AbilityTypes.CREW
export (PackedScene) var ability_scene: PackedScene
onready var ability_list: = $VBox
#
#func _ready() -> void:
#	match type:
#		AbilityTypes.CREW:
#			Events.connect("crew_loaded", self, "_on_playbook_loaded")
#			setup(GameData.crew_playbook)
#		AbilityTypes.PC:
#			Events.connect("character_selected", self, "_on_playbook_loaded")


func setup(playbook:Playbook)->void:
	_playbook = playbook

	for ability_name in playbook.abilities:
		var new_ability: = ability_scene.instance()
		ability_list.add_child(new_ability)
		var ability = playbook.abilities[ability_name]
		new_ability.playbook = playbook
		new_ability.effect = ability.effect
		new_ability.claimed = ability.claimed
		new_ability.ability = ability.ability
		new_ability.setup(playbook)



func _on_playbook_loaded(playbook: Playbook)-> void:
	_playbook = playbook

	for child in ability_list.get_children():
		if child is Ability:
			child.queue_free()
	setup(playbook)
