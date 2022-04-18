extends Control


export (PackedScene) var marker_scene
onready var stat_name_label: = $VBoxContainer/HBoxContainer/stat_name
onready var stat_level_label: = $VBoxContainer/HBoxContainer/stat_level
onready var stat_container: = $VBoxContainer
onready var stat_hbox: = $VBoxContainer/HBoxContainer
var stats: = []
var stat_containers: = []
onready var xp: = $VBoxContainer/HBoxContainer/xp
var playbook: Playbook setget _set_playbook
var level: = 0 setget _set_level
export (String) var stat_name: = ""
export (Array, String) var substats
export (int) var stat_max_level
export (bool) var verticle_sort: = true

func _ready() -> void:
	name = stat_name
	stat_name_label.text = stat_name
	stat_name = stat_name.to_lower()
	xp.playbook_field = "experience."+stat_name
	stat_level_label.playbook_field = stat_name
	if not verticle_sort:
		var new_hbox: = HBoxContainer.new()
		for child in stat_container.get_children():
			stat_container.remove_child(child)
			new_hbox.add_child(child)

		stat_container.queue_free()
		stat_container = new_hbox
		var new_vbox: = VBoxContainer.new()
		add_child(new_vbox)
		stat_container.remove_child(stat_hbox)
		new_vbox.add_child(stat_hbox)
		new_vbox.add_child(stat_container)

	if not stat_containers.empty():
		for container in stat_containers:
			stat_container.add_child(container)


func setup()-> void:
	clear_substats()
	create_substats()
	_connect_to_signals()
	calculate_level()


func _set_playbook(value: Playbook)-> void:
	playbook = value
	setup()

func clear_substats()-> void:
	for stat in stats:
		stat.queue_free()
	stats.clear()
	stat_containers.clear()
	level = 0


func create_substats()-> void:
	if not playbook: return
	for stat in substats:
		var hbox: = HBoxContainer.new()
		var stat_marker: = marker_scene.instance() as Markers
		stat_marker.total_points = stat_max_level
		stat_marker.label = stat
		stat_marker.playbook = playbook
		stat_marker.playbook_field = "stats."+ stat_name.to_lower() +"."+stat.to_lower()
		stats.append(stat_marker)
		hbox.add_child(stat_marker)
		if stat_container:
			stat_container.add_child(hbox)
		else:
			stat_containers.append(hbox)

func _on_filled_points_changed(_filled_points: int)-> void:
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
	if stat_level_label:
		stat_level_label.text = "(Level: " + str(level) + ")"
