class_name Coin
extends Control

export (bool) var pressed: bool setget _set_pressed
onready var anim: AnimationPlayer = $Sprite/AnimationPlayer
onready var parent: Node = get_parent()


func _set_pressed(value: bool)->void:
	pressed = value
	if value == true:
		anim.play("coin_added")
		if "filled_points" in parent:
			parent.filled_points += 1
	elif value == false:
		anim.play("coin_removed")
		if "filled_points" in parent:
			parent.filled_points -= 1

func _on_Coin_mouse_entered() -> void:
	if pressed:
		anim.play("coin_rotate")
		anim.get_animation(anim.current_animation).loop = true


func _on_Coin_mouse_exited() -> void:
	if pressed:
		if anim.is_playing():
			anim.get_animation(anim.current_animation).loop = false
		anim.queue("idle")


func _on_Coin_input_event(event: InputEvent) -> void:
	if event.is_action_pressed("left_click"):
		if pressed:
			self.pressed = false
		else:
			self.pressed = true


func reset()->void:
	if pressed:
		anim.play("coin_removed")
		anim.queue("idle")
	pressed = false

func load_set()->void:
	if anim: anim.play("coin_added")
	pressed = true
