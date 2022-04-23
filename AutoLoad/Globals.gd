extends Node

#This is being used for the new game popup
const GAME_SCENE_PATH: = "res://game/Game.tscn"
const GAME_SCENE:PackedScene = preload(GAME_SCENE_PATH)
var DEFAULT_MAP_IMAGE: = preload("res://maps/blades_detailedmap_highres.jpg")
var grid: TileMap
enum CLOCK_TYPE {
	ALL,
	OBSTACLE,
	HEALING,
	LONG_TERM_PROJECT,
	LAIR_PROJECT,
	PC_PROJECT,
	FACTION_PROJECT
}

enum OP_CODES {
	PLAYER_UPDATE
}

#Helper Functions
func propagate_set_playbook_recursive(node: Node, playbook: Playbook, starting_node: Node)-> void:
	var is_playbook_set:= false
	if "playbook" in node and node != starting_node:
		node.set("playbook", playbook)
	elif "_playbook" in node and node != starting_node:
		node.set("_playbook", playbook)

	for child in node.get_children():
		propagate_set_playbook_recursive(child, playbook, starting_node)


func list_files_in_directory(path:String)->Array:
	var files: = []
	var dir: = Directory.new()
	dir.open(path)
	dir.list_dir_begin()

	while true:
		var file = dir.get_next()
		if file == "": break
		elif file.ends_with(".tres") and not file.begins_with(".") and not file.ends_with("crew.tres"):
			files.append(file)

	dir.list_dir_end()
	return files

func list_folders_in_directory(path:String)->Array:
	var folders: = []
	var dir:= Directory.new()
	if dir.open(path) == OK:
		dir.list_dir_begin()
		var file_name:String = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
#				print("Found directory: " + file_name)
				if not file_name.begins_with("."):
					folders.append(file_name)
			else:
				print("Found file: " + file_name)
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")
	return folders


func get_all_children_in_group_recursive(node: Node, group: String)->Array:
	var nodes: Array = []

	for child in node.get_children():
		if child.get_child_count() > 0:
			if child.is_in_group(group):
				nodes.append(child)
			nodes.append_array(get_all_children_in_group_recursive(child, group))
		else:
			if child.is_in_group(group):
				nodes.append(child)
	return nodes


func convert_to_grid(position:Vector2)-> Vector2:
	var converted_pos:Vector2 = grid.to_local(position)
	converted_pos = grid.world_to_map(converted_pos)
	return converted_pos


func str_to_vec2(string:="")->Vector2:
	var formatted_str: = string.replace("(", "").replace(")", "").strip_edges()
	var str_array: Array = formatted_str.split_floats(",")
	var vec2:= Vector2(str_array[0], str_array[1])
	return vec2


func propagate_set_playbook_fields_recursive(node:Node, field_template:String)-> void:
	for child in node.get_children():
		if "playbook_field" in child:
			if "modular_playbook_field_ending" in child and child.modular_playbook_field_ending:
				child.playbook_field = (field_template + child.modular_playbook_field_ending).trim_prefix(".")
			else:
				child.playbook_field = field_template
		if child.get_child_count() > 0:
			propagate_set_playbook_fields_recursive(child, field_template)
