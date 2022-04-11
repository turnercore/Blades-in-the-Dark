extends Node

#This is being used for the new game popup
const GAME_SCENE_PATH: = "res://game/Game.tscn"
const GAME_SCENE:PackedScene = preload(GAME_SCENE_PATH)
const DEFAULT_MAP_IMAGE:= "res://maps/blades_detailedmap_highres.jpg"

enum CLOCK_TYPE {
	ALL,
	OBSTACLE,
	HEALING,
	LONG_TERM_PROJECT,
	LAIR_PROJECT,
	PC_PROJECT,
	FACTION_PROJECT
}

#Helper Functions
func propagate_set_playbook_recursive(node: Node, playbook: Playbook, starting_node: Node)-> void:
	if "playbook" in node and node != starting_node:
		node.set("playbook", playbook)
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
				print("Found directory: " + file_name)
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
