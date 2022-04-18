extends PopupScreen

const TIME_BETWEEN_FRAMES: = 0.05
var roll_timing: = 2.0
export (PackedScene) var dice_scene
export (bool) var rolling: = true
var total:int
export (int) var num_of_dice: int = 0
onready var result_label: = $PanelContainer/VBoxContainer/HBoxContainer/result
onready var result_label2: = $PanelContainer/VBoxContainer/HBoxContainer2/result
var with_advantage:= true
var result:int

onready var positions:=[
	{
		"position": $Position2D,
		"occupied": null
	},
	{
		"position": $Position2D2,
		"occupied": null
	},
	{
		"position": $Position2D3,
		"occupied": null
	},
	{
		"position": $Position2D4,
		"occupied": null
	},
	{
		"position": $Position2D5,
		"occupied": null
	},
	{
		"position": $Position2D6,
		"occupied": null
	}
]


func _ready()-> void:
	create_dice(num_of_dice)
	$PanelContainer/VBoxContainer/RollingInfo/TimingSlider.value = roll_timing
	$PanelContainer/VBoxContainer/RollButton.disabled = true

func roll_dice()-> void:
	randomize()
	while rolling:
		for position in positions:
			var rand_number:int = randi() % 6
			if position.occupied != null:
				position.occupied.frame = rand_number
		yield(get_tree().create_timer(TIME_BETWEEN_FRAMES), "timeout")


func calculate_best()-> int:
	var rolls: = []
	for position in positions:
		if position.occupied != null:
			rolls.append(int(position.occupied.frame) + 1)
	return rolls.max()


func calculate_worst()-> int:
	var rolls: = []
	for position in positions:
		if position.occupied != null:
			rolls.append(int(position.occupied.frame) + 1)
	return rolls.min()


func create_dice(amount: int)-> void:
	for position in positions:
		if position.occupied != null:
			position.occupied.queue_free()
			position.occupied = null

	for i in amount:
		var new_dice = dice_scene.instance()
		var position_set: = false
		var unoccupied_pos: Array
		for position in positions:
			if position.occupied == null:
				unoccupied_pos.append(position)

		var rand_index: int = randi() % unoccupied_pos.size()
		add_child(new_dice)
		unoccupied_pos[rand_index].occupied = new_dice
		new_dice.position = unoccupied_pos[rand_index].position.position


func display_roll()-> void:
	var roll:int = calculate_best() if with_advantage else calculate_worst()
	var crit_threat: = false
	var crit: = false

	for position in positions:
		if position.occupied != null:
			if position.occupied.frame == roll - 1:
				if crit_threat:
					crit = true
				result = display_result(roll if not crit else 12)
				match result:
					1:
						position.occupied.modulate = Color.red
					2:
						position.occupied.modulate = Color.yellow
					3:
						position.occupied.modulate = Color.green
					4:
						position.occupied.modulate = Color.gold
#			breakpoint
			#Check for crits
				if roll == 6 and with_advantage:
					crit_threat = true
				if roll != 6:
					break
				else:
					continue


func display_result(result_roll:int)-> int:
	var result:=""
	var result_value:int = -1


	if result_roll <= 3:
		result = "Bad Outcome"
		result_value = 1
	elif result_roll > 3 and result_roll < 6:
		result = "Partial Success"
		result_value = 2
	elif result_roll == 6:
		result = "Full Success!"
		result_value = 3
	elif result_roll > 6:
		result = "CRITICAL SUCCESS!!!"
		result_value = 4
	else:
		result = "invalid result"

	result_label.text = result
	result_label.visible = true
	result_label2.text = result
	result_label2.visible = true
	return result_value


func reset_dice()-> void:
	for position in positions:
		if position.occupied != null:
			position.occupied.modulate = Color.white


func _on_RollButton_pressed() -> void:
	if num_of_dice == 0:
		$PanelContainer/VBoxContainer/RollButton.disabled = true
		return

	reset_dice()
	rolling = true
	$PanelContainer/VBoxContainer/RollButton.disabled = true
	roll_dice()

	yield(get_tree().create_timer(roll_timing), "timeout")

	display_roll()
	rolling = false
	$PanelContainer/VBoxContainer/RollButton.disabled = false


func _on_AmountOfDice_item_selected(index: int) -> void:
	if index > 0:
		$PanelContainer/VBoxContainer/RollButton.disabled = false
	elif index == 0:
		$PanelContainer/VBoxContainer/RollButton.disabled = true
	num_of_dice = index
	create_dice(index)


func _on_TimingSlider_value_changed(value: float) -> void:
	roll_timing = value


func _on_AdvantageOption_item_selected(index: int) -> void:
	match index:
		0:
			with_advantage = true
		1:
			with_advantage = false
		_:
			with_advantage = false


func _on_result_mouse_entered() -> void:
	print("Mouse entered")
	var title: = ""
	var info: = ""
	match result:
		1:
			title = "Bad Outcome"
			info = "It's a bad outcome. Things go poorly. You probably don't achieve your goal and you suffer complications as well."
		2:
			title = "Partial Success"
			info = "You do what you were trying to do! ...but, there are consequences. Expect some kind of trouble, harm, reduced effect, etc."
		3:
			title = "Full Success!"
			info = "Way to go! Things go well. You do what you were trying to do, how you were trying to do it."
		4:
			title = "Critical Success!!"
			info = "WOW! Look at you, you achieved your goal and then some. You gain some addtional advantage on top of a full success."

	Tooltip.display_tooltip(title, info)


func _on_result_mouse_exited() -> void:
	Tooltip.finish_tooltip()
