extends Node

const GAME_SCENE:PackedScene = preload("res://game/Game.tscn")
const DEFAULT_MAP_ID: = "doskfull"
const DEFAULT_MAP_NAME: = "Doskvol"
var DEFAULT_MAP_IMAGE: = preload("res://maps/blades_detailedmap_highres.jpg")
const GRID_SIZE: = Vector2(5, 5)

var grid: = TileMap.new()
var ids: = []


func _ready() -> void:
	grid.cell_size = GRID_SIZE
	add_child(grid)

#Helper Functions
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
	if not grid.is_inside_tree():
		grid = TileMap.new()
		grid.cell_size = GRID_SIZE
		add_child(grid)
	var converted_pos:Vector2 = grid.to_local(position)
	converted_pos = grid.world_to_map(converted_pos)
	return converted_pos

func map_to_world(map_pos:Vector2)->Vector2:
	var world_pos: = Vector2.ZERO
	if not grid.is_inside_tree():
		grid = TileMap.new()
		grid.cell_size = GRID_SIZE
		add_child(grid)

	world_pos = grid.map_to_world(map_pos)
	return world_pos

func world_to_map(world_pos:Vector2)->Vector2:
	var map_pos: = Vector2.ZERO
	if not grid.is_inside_tree():
		grid = TileMap.new()
		grid.cell_size = GRID_SIZE
		add_child(grid)

	map_pos = grid.world_to_map(world_pos)
	return map_pos


func str_to_vec2(string:="(0,0)")->Vector2:
	var formatted_str: = string.replace("Vector2", "").replace("(", "").replace(")", "").strip_edges()
	var str_array: Array = formatted_str.split_floats(",")
	var vec2:= Vector2(str_array[0], str_array[1])
	return vec2

func str_to_color(string:="1, 1, 1, 1")->Color:
	var split:PoolStringArray = string.split(",")
	var r:float = float(split[0])
	var g:float = float(split[1])
	var b:float = float(split[2])
	var a:float = float(split[3])
	var color: = Color(r, g, b, a)
	return color


func str2poolvec2array(points:String)-> PoolVector2Array:
	var result: = []
	var split:PoolStringArray = points.replace("[", "").replace("]", "").split("),")
	for strvec2 in split:
		strvec2 += ")"
		result.append(str_to_vec2(strvec2))
	return PoolVector2Array(result)


func propagate_set_property_recursive(node:Node, property:String, value)-> void:
	for child in node.get_children():
		if property in child:
			child.set(property, value)
		if child.get_child_count() > 0:
			propagate_set_property_recursive(child, property, value)


func generate_id(characters:int)-> String:
	randomize()
	var possible_characters: = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"
	var id:=""
	for character in characters:
		var rand:int = randi() % possible_characters.length()
		id += possible_characters[rand]
	#Prevent duplicate ids being generated (as unlikely as that is)
	if ids.has(id):
		id = generate_id(characters)
	return id


##Testing values of things
func _process(_delta: float) -> void:
	pass
