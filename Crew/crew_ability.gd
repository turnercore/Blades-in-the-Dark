class_name CrewAbility
extends HBoxContainer

var ability: String = ""
var effect: String = ""
var claimed: bool = false


func _ready()-> void:
	$ability.text = ability + ": "
	$effect.text = effect
	$CheckBox.pressed = claimed
