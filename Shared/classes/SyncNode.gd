class_name SyncNode
extends Control

#Remember to add some sort of ID

const SYNC_INTERVAL:float = 1.0
var is_checking_for_updates: = true
#var has_been_updated: = false
var export_properties: = []
var old_data: = {}

signal updated(data)
signal group_deleted
signal freed

func _ready()-> void:
	for property in export_properties:
		if property in self:
			old_data[property] = get(property)

	var sync_timer: = Timer.new()
	sync_timer.one_shot = false
	sync_timer.connect("timeout", self, "check_for_updates")
	add_child(sync_timer)
	sync_timer.start(SYNC_INTERVAL)


func check_for_updates()-> void:
	if is_checking_for_updates:
		var updated_data: = {}
		for property in export_properties:
			if old_data[property] != get(property):
				old_data[property] == get(property)
				updated_data[property] = get(property)

		if not updated_data.empty():
			emit_signal("updated", updated_data)

func package()-> Dictionary:
	var data: = {}
	for property in export_properties:
		if property in self:
			data[property] = get(property)
	return data


func import(data:Dictionary)-> void:
	var updated_data: = {}
	for property in data:
		if property in self:
			if get(property) is Vector2 and data[property] is String:
				data[property] = str_to_vec2(data[property])
			if get(property) is Color and data[property] is String:
				data[property] = str_to_color(data[property])
			if data[property] != get(property):
				set(property, data[property])
				updated_data[property] = data[property]

	if not updated_data.empty():
		emit_signal("updated", updated_data)

func delete_connected()-> void:
	emit_signal("group_deleted")

func generate_id(characters:int)-> String:
	var possible_characters: = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"
	var id:=""
	for character in characters:
		var rand:int = randi() % possible_characters.length()
		id += possible_characters[rand]

	return id

func str_to_vec2(string:="")->Vector2:
	var formatted_str: = string.replace("(", "").replace(")", "").strip_edges()
	var str_array: Array = formatted_str.split_floats(",")
	var vec2:= Vector2(str_array[0], str_array[1])
	return vec2

func str_to_color(string:="")->Color:
	var split:PoolStringArray = string.split(",")
	var r:float = float(split[0])
	var g:float = float(split[1])
	var b:float = float(split[2])
	var a:float = float(split[3])
	var color: = Color(r, g, b, a)
	return color

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		emit_signal("freed")
