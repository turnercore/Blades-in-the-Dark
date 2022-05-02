class_name Markers
extends SaveableField

export (PackedScene) var exp_point_scene
export (int, 0, 100) var total_points: = 0
export (int, 0, 100) var filled_points:int = 0 setget _set_filled_points
export (String) var label: = ""
#export (String) var property_saved:String = "filled_points"
var points: = []
var changes_locked: bool = false
#signal property_updated(name, property)
signal filled_points_changed

func _ready() -> void:
	if not exp_point_scene:
		return

	if not (exp_point_scene.instance() is Control):
		print("exp point wasn't a Control")
		return

	$Label.text = label
	load_from_resource(resource)
	var start_filled_points: = filled_points
	for _point in range(total_points):
		var new_point: Control = exp_point_scene.instance()
		if start_filled_points > 0:
			new_point.load_set()
			start_filled_points -= 1
		add_child(new_point)
		points.append(new_point)


func _set_filled_points(value: int)-> void:
	if changes_locked: return

	if points.size() <= 0:
		filled_points = value
	else:
		filled_points = int(clamp(value, 0, points.size()))
	changes_locked = true
	for i in filled_points:
		if points.size() <= 0: break
		if points[i].pressed != true: points[i].pressed = true
	for point in points.slice(filled_points, -1):
		if point.pressed != false: point.pressed = false
	changes_locked = false

	emit_signal("filled_points_changed", filled_points)


func _on_load(new_resource: NetworkedResource)->void:
	changes_locked = true
	for point in points:
		point.reset()
	for i in range(get(property)):
		points[i].load_set()

	changes_locked = false
	var updated_property = resource.find(field)
	if updated_property:
		set(property, updated_property)
	else: filled_points = 0

