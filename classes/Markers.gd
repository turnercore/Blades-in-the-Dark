extends SaveableField

export (PackedScene) var exp_point_scene
export (int, 0, 100) var total_points: = 0
export (int, 0, 100) var filled_points: = 0 setget _set_filled_points
#export (String) var property_saved:String = "filled_points"
var points: = []
var changes_locked: bool = false
#signal property_updated(name, property)

func _ready() -> void:
	if not exp_point_scene:
		return

	if not (exp_point_scene.instance() is Control):
		print("exp point wasn't control")
		return

	var start_filled_points: int = filled_points
	for point in range(total_points):
		var new_point: Control = exp_point_scene.instance()
		if start_filled_points > 0:
			new_point.pressed = true
			start_filled_points -= 1
		add_child(new_point)
		points.append(new_point)


func _set_filled_points(value: int)-> void:
	if changes_locked: return
	filled_points = clamp(value, 0, points.size())
	emit_signal("property_updated", playbook_field, filled_points)


func _on_load(playbook: Playbook)->void:
	changes_locked = true
	for point in points:
		point.reset()
	for i in range(get(property_saved)):
		points[i].load_set()

	changes_locked = false
	var updated_property = playbook.find(playbook_field)
	if updated_property:
		set(property_saved, updated_property)
	else: filled_points = 0

