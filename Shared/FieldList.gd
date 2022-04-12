class_name FieldList
extends ScrollContainer

export (String) var playbook_data
export (String) var title setget _set_title
export (PackedScene) var field_scene: PackedScene

var _playbook:Playbook setget _on_playbook_loaded
onready var list: = $List
onready var title_label: = $List/Title


func _ready()-> void:
	title_label.text = title



func setup(playbook:Playbook)->void:
	_playbook = playbook

	for key in playbook[playbook_data]:
		#add the field scene to the list
		var field: = field_scene.instance()
		list.add_child(field)


		var playbook_field = playbook[playbook_data][key]
		for property in playbook_field:
			if property in field:
				field.set(property, playbook_field[property])

		#Set the playbook on the field (this may be redundent
		field.playbook = playbook
		if "setup" in field: field.setup(playbook)



func _on_playbook_loaded(playbook: Playbook)-> void:
	print("playbook loaded to abilities")
	_playbook = playbook

	for child in list.get_children():
		if child is Ability:
			child.queue_free()

	setup(playbook)


func _set_title(value:String)-> void:
	title = value
	if title_label: title_label.text = value
