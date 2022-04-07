extends Control

const marker_scene: = preload("res://Shared/Markers.tscn")

onready var stat_name_label: = $VBoxContainer/HBoxContainer/stat_name
onready var stat_level_label: = $VBoxContainer/HBoxContainer/stat_level
onready var stat_container: = $VBoxContainer
onready var stats: = []
onready var xp: = $VBoxContainer/HBoxContainer/xp
onready var parent: = get_parent()

var level: = 0 setget _set_level
export (String) var stat_name: = ""
export (Array, String) var substats
export (int) var stat_max_level
export (bool) var verticle_sort: = true

func _ready() -> void:
	name = stat_name
	stat_name_label.text = stat_name
	if not verticle_sort:
		var new_hbox: = HBoxContainer.new()
		for child in stat_container.get_children():
			stat_container.remove_child(child)
			new_hbox.add_child(child)
		stat_container.queue_free()
		stat_container = new_hbox
		add_child(stat_container)

	create_substats()
	_connect_to_signals()
	calculate_level()
	if get_parent() is Container:
		parent = parent as Container
		parent.queue_sort()


func create_substats()-> void:
	for stat in substats:
		var hbox: = HBoxContainer.new()
		var stat_marker: = marker_scene.instance()
		stat_marker.total_points = stat_max_level
		stat_marker.label = stat
		stats.append(stat_marker)

		hbox.add_child(stat_marker)
		stat_container.add_child(hbox)

func _on_filled_points_changed(filled_points: int)-> void:
	calculate_level()


func calculate_level()-> void:
	self.level = 0
	for stat in stats:
		if stat.filled_points >= 1:
			self.level += 1

func _connect_to_signals()-> void:
	for stat in stats:
		if stat.has_signal("filled_points_changed"):
			stat.connect("filled_points_changed", self, "_on_filled_points_changed")


func _set_level(value: int)-> void:
	level = value
	stat_level_label.text = "(Level: " + str(level) + ")"
