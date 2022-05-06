class_name FieldList
extends Container

export (String) var playbook_data
export (String) var title setget _set_title
export (String) var include_only: = ""
export (PackedScene) var field_scene: PackedScene

var resource:NetworkedResource setget _set_resource
export (NodePath) onready var list = get_node(list)
export (NodePath) onready var title_label = get_node(title_label)

export (bool) var keep_updated: = true
export (bool) var compact: = false

func _ready()-> void:
	title_label.text = title


func setup()->void:
	pass
#	var playbook = _playbook
#	if not playbook_data in playbook:
#		print("playbook data not found " + str(playbook_data) + " in playbook " + str(playbook))
#		return
#
#	for child in list.get_children():
#		if not child == title_label:
#			child.queue_free()
#
#	for key in playbook[playbook_data]:
#		var playbook_field = playbook[playbook_data][key]
#		#if an include is set, only include those that have that property as well
#		if include_only:
#			if not include_only in playbook_field or not playbook_field[include_only]:
#				continue
#
#		#add the field scene to the list
#		var field: = field_scene.instance()
#		if "compact" in field: field.compact = self.compact
#		list.add_child(field)
#
#		for property in playbook_field:
#			if property == "name":
#				field.set(property, playbook_field[property])
#				if "id" in field:
#					field.set("id", playbook_field[property])
#			elif property in field:
#				field.set(property, playbook_field[property])
#
#		#Set the playbook on the field (this may be redundent
#		if "playbook" in field: field.playbook = playbook
#		if "_playbook" in field: field._playbook = playbook
#		if "setup" in field: field.setup(playbook)


func _set_resource(new_resource: NetworkedResource)-> void:
	resource = new_resource
	if not resource.is_connected("property_changed", self, "_on_resource_property_changed"):
		resource.connect("property_changed", self, "_on_resource_property_changed")
	setup()


func _set_title(value:String)-> void:
	title = value
	if title_label is Node: title_label.text = value


func _on_resource_property_changed(updated_property:String, value)-> void:
	pass
