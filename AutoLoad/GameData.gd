extends Node

const DEFAULT_MAP_NOTE_ICON:String= "res://Shared/Art/Icons/MapNoteIconTex.tres"

const DEFAULT_NOTE: = {
	"description": "DEFAULT INFO TEXT",
	"location_name": "LOCATION",
	"tags": "",
	"pos": Vector2.ZERO,
	"icon": DEFAULT_MAP_NOTE_ICON,
	"shortcut": false
}

const ALLOWED_RPCS: = [
	"update_map_note",
	"add_map_note",
	"remove_map_note",
	"update_clock",
	"create_map",
	"change_map_to",
	"load_crew",
	"remote_update_variable"
]

const OP_CODE:int = Globals.OP_CODES.GAMEDATA_UPDATE

export (Resource) var crew_playbook = null

#This should be updated to remove the "roster" checks and just be an Array itself
export (Dictionary) var pc_playbooks:Dictionary
#{
	#Roster is an array of inactive playbooks
	#"roster": [
#		PlayerPlaybook,
#		PlayerPlaybook
	#]
#}

export (Resource) var save_game = SaveGame.new() setget _set_save_game

#The active character, needs to be updated for multiplayer
var active_pc: PlayerPlaybook setget _set_active_pc
#Store a reference to the current srd, used for looking up and displaying it in info
var srd
#This could probably be reworked into an array
var clocks: = {
#	"clock_0" : {
#		"id": "clock_0",
#		"clock_name": "clock",
#		"filled": 0,
#		"max_value": 4,
#		"locked": false,
#		"locked_by_clock": null,
#		"unlocks_clock": null,
#		"type": Globals.CLOCK_TYPE.OBSTACLE,
#		"is_secret": false,
#		"fill_color: Color.black
#		}
}

var map:Dictionary = {
	"map_index": 0,
	"map_name": "Duskvol",
	"image": null,
	"notes": {},
	"srd_notes": {}
	} setget _set_map

#ARRAY OF MAP NOTES a map note is a location
var map_shortcuts:Array
var clocks_being_saved: = false

var game_state:String = "Free Play" setget _set_game_state

var is_game_setup: = false setget _set_is_game_setup
var needs_current_game_state:bool = false
var online: = false

#Signals
signal crew_changed
signal clocks_loaded(clocks)
signal map_loaded(map)
#I think these are unused
signal pc_playbooks_changed
signal clocks_free
signal map_shortcut_added
signal map_shortcut_removed
signal game_state_changed(game_state)
signal game_setup

func _ready() -> void:
	connect_to_signals()

	if pc_playbooks and "roster" in pc_playbooks:
		for playbook in pc_playbooks:
			if not playbook is PlayerPlaybook: continue
			if not playbook.is_connected("changed", self, "_on_playbook_updated"):
				playbook.connect("changed", self, "_on_playbook_updated", [playbook])


func connect_to_signals()-> void:
	Events.connect("clock_updated", self,"_on_clock_updated")
	Events.connect("map_created", self, "_on_map_created")
	Events.connect("map_changed", self, "_on_map_changed")
	Events.connect("map_removed", self, "_on_map_removed")
	Events.connect("map_note_updated", self, "_on_map_note_updated")
	Events.connect("map_note_created", self, "_on_map_note_created")
	Events.connect("map_note_removed", self, "_on_map_note_removed")
	ServerConnection.connect("match_joined", self, "_on_match_joined")
	ServerConnection.connect("data_recieved", self, "_on_data_recieved")
	if not GameSaver.is_connected("save_loaded", self, "_on_save_loaded"):
		GameSaver.connect("save_loaded", self, "_on_save_loaded")
	if not GameSaver.is_connected("crew_loaded", self, "_on_crew_loaded"):
		GameSaver.connect("crew_loaded", self, "_on_crew_loaded")
	if not GameSaver.is_connected("pc_playbooks_loaded", self, "_on_pc_playbooks_loaded"):
		GameSaver.connect("pc_playbooks_loaded", self, "_on_pc_playbooks_loaded")

#Remote function
func load_pc_playbooks(playbooks:Array)-> void:
	pc_playbooks = {}
	if not pc_playbooks: pc_playbooks = {"roster": []}
	elif not "roster" in pc_playbooks: pc_playbooks["roster"] = []
	pc_playbooks["roster"] = playbooks

	for playbook in playbooks:
		if not playbook is PlayerPlaybook: continue
		if not playbook.is_connected("changed", self, "_on_playbook_updated"):
			playbook.connect("changed", self, "_on_playbook_updated", [playbook])

#Online enabled
func _on_pc_playbooks_loaded(playbooks:Array)-> void:
	load_pc_playbooks(playbooks)
	if online: yield(ServerConnection.send_rpc_async("load_pc_playbooks", OP_CODE, playbooks), "completed")


func _on_playbook_updated(playbook:Playbook)->void:
	GameSaver.save(playbook)


func _on_clock_updated(id:String, clock_data:={})->void:
	var data: = {
		"id": id,
		"clock_data": clock_data
	}
	update_clock(data)
	if online: yield(ServerConnection.send_rpc_async("update_clock", OP_CODE, data), "completed")

func update_clock(data:Dictionary)-> void:
	var clock_data:Dictionary = data.clock_data if "clock_data" in data else {}
	var id:String = data.id if "id" in data else ""

	if clock_data.empty():
			clocks.erase(id)
	else:
		clocks[id] = clock_data
	save_clocks()


func _on_save_loaded(save:SaveGame)->void:
	self.save_game = save
	self.srd = save.srd_data
	self.clocks = save.clocks
	emit_signal("clocks_loaded", clocks)
	save.setup_srd_maps()
	self.map = save._map if save._map else save.maps[0]
	emit_signal("map_loaded", map)
	self.is_game_setup = true


#func load_map_from(save:SaveGame)-> Dictionary:
#	var loaded_map:= save.map if save.map else save.maps[0]
#	#reload the srd notes in case they've changed
#	if "srd_notes" in loaded_map and loaded_map.srd_notes.empty():
#		loaded_map.srd_notes = srd.default_locations
#
#
#	emit_signal("map_loaded", loaded_map)
#	return loaded_map

func _set_save_game(new_save: SaveGame)-> void:
	if new_save.needs_setup: new_save.setup_save()
	clocks = new_save.clocks
	map = new_save._map
	save_game = new_save


func _set_clocks_being_saved(value: bool)-> void:
	if not value: emit_signal("clocks_free")
	clocks_being_saved = value


#Package the data, push it to GameSaver, bosh
func save_all()-> void:
	var data: = []
	save_clocks()
	save_map()
	data = [save_game, crew_playbook, pc_playbooks]
	GameSaver.save_all(data)

#Adds a newly created (or imported) character to the roster and save
func add_pc_to_roster(pc:PlayerPlaybook)-> void:
	pc_playbooks.roster.append(pc)
	GameSaver.save(pc)


#Saves the current map as well as updating the maps Array in save_game
func save_map()-> void:
	var map_previously_existed:= false

	for saved_map in save_game.maps:
		if map.map_name and saved_map.map_name:
			if map.map_name == saved_map.map_name:
				var index:int = save_game.maps.find(saved_map)
				save_game.maps[index] = map
				map_previously_existed = true

	if not map_previously_existed:
		save_game.maps.append(map)

	save_game._map = map

#Add or edit the map note
#Remote function
func add_map_note(data:Dictionary)-> void:
	var pos:Vector2 = data.pos if data.pos is Vector2 else Globals.str_to_vec2(data.pos)

	if not "notes" in map:
		map["notes"] = {}

	if pos in map.notes: return

	map.notes[pos] = data
#	map.notes[pos]["pos"] = pos
	if "shortcut" in data:
		add_map_shortcut(data)
	save_map()

#I'm no longer completely sure why I have a lockout variable (and signal) to save the clocks...
func save_clocks()->void:
	self.clocks_being_saved = true
	save_game.clocks = clocks
	self.clocks_being_saved = false


func get_clocks()-> Array:
	if clocks_being_saved:
		yield(self, "clocks_free")
	clocks = save_game.clocks
	return clocks

#Online enabled
func _on_crew_loaded(crew: CrewPlaybook)-> void:
	load_crew(crew)
	if online: yield(ServerConnection.send_rpc_async("load_crew", OP_CODE, crew), "completed")

#Remote function
func load_crew(crew:CrewPlaybook)-> void:
	if crew_playbook:
		if crew_playbook.is_connected("changed", self, "_on_playbook_updated"):
			crew_playbook.disconnect("changed", self, "_on_playbook_updated")
	if not crew.is_connected("changed", self, "_on_playbook_updated"):
		crew.connect("changed", self, "_on_playbook_updated",[crew])
	crew_playbook = crew


func _set_active_pc(playbook: PlayerPlaybook)->void:
	active_pc = playbook
	Events.emit_character_selected(playbook)

#Remote Enabled
func create_map(data:Dictionary)-> void:
	if not "image_path" in data or not "map_name" in data:
		return
	var image_path:String = data.image_path
	var map_name:String = data.map_name

	if "map_index" in map:
		map.map_index = save_game.maps.size()
		map.notes = {}
		map.map_name = map_name
		map.image = image_path
		save_game.maps.append(map)
		emit_signal("map_loaded", map)

#Online enabled
func _on_map_created(image_path: String, map_name: String)-> void:
	var data: = {
		"image_path": image_path,
		"map_name": map_name
	}
	create_map(data)
	if online: yield(ServerConnection.send_rpc_async("create_map", OP_CODE, data), "completed")

#Remote emabled
func change_map_to(index:int)-> void:
	save_map()
	map = save_game.maps[index]
	save_game._map = map
	emit_signal("map_loaded", map)

#Online enabled
func _on_map_changed(index:int)-> void:
	if index < save_game.maps.size() and index > -1:
		change_map_to(index)
		if online: yield(ServerConnection.send_rpc_async("change_map_to", OP_CODE, index), "completed")
	else:
		print("Error map index out of range")


func _on_map_removed(index:int)->void:
	if index < save_game.maps.size() and index > -1:
		save_game.maps.remove(index)
	else:
		print("Error map index out of range")

#Online enabled
func _on_map_note_updated(data: Dictionary)-> void:
	update_map_note(data)
	if online: yield(ServerConnection.send_rpc_async("update_map_note", OP_CODE, data), "completed")


func update_map_note(data: Dictionary):
	if not data.pos in map.notes:
		print("error somehow couldn't find note in map")
		return

	var note:Dictionary = map.notes[data.pos]
	for value in data:
		if value in note:
			note[value] = data[value]

	add_map_shortcut(note)
	save_map()
	emit_signal("map_loaded", map)


func add_map_shortcut(note:Dictionary)-> void:
	if note.shortcut and not map_shortcuts.has(note):
		map_shortcuts.append(note)
	emit_signal("map_shortcut_added")


func remove_map_shortcut(note:Dictionary)-> void:
	if map_shortcuts.has(note):
			map_shortcuts.erase(note)
	emit_signal("map_shortcut_removed")


func remove_map_note(note: Vector2)-> void:
	var grid_pos: = Globals.convert_to_grid(note)
	if map.notes.has(grid_pos):
		remove_map_shortcut(map.notes.get(grid_pos))
		map.notes.erase(grid_pos)
	save_map()
	emit_signal("map_loaded", map)

#Online enabled
func _on_map_note_removed(note: Vector2)-> void:
	remove_map_note(note)
	if online: yield(ServerConnection.send_rpc_async("remove_map_note", OP_CODE, note), "completed")


func _set_map(value:Dictionary)-> void:
	map_shortcuts = []
	map = value
	for location in map.notes:
		if "shortcut" in map.notes[location] and map.notes[location].shortcut:
			add_map_shortcut(map.notes[location])

#Online enabled
func _on_map_note_created(note_data:Dictionary)-> void:
	add_map_note(note_data)
	if online: yield(ServerConnection.send_rpc_async("add_map_note", OP_CODE, note_data), "completed")

#Online enabled
func _set_game_state(value:String)-> void:
	game_state = value
	emit_signal("game_state_changed", value)
	var data: ={
		"variable": "game_state",
		"value": value
	}
	if online: yield(ServerConnection.send_rpc_async("remote_update_variable", OP_CODE, data), "completed")


func _set_is_game_setup(value:bool)-> void:
	is_game_setup = value
	if is_game_setup:
		emit_signal("game_setup")


#Multiplayer Functions to keep data the same between everyone


func _on_match_joined()-> void:
	online = true
	if not ServerConnection.is_host:
		needs_current_game_state = true


func _on_data_recieved(payload:Dictionary)-> void:
	if needs_current_game_state and "op_code" in payload and payload.op_code == Globals.OP_CODES.INTIAL_GAME_STATE:
		if "GameData" in payload.data:
			for property in payload.data.GameData:
				if property in self:
					set(property, payload.data.GameData[property])
		needs_current_game_state = false
		return

	#Make sure data is formatted correctly
	if not "rpc" in payload or not "op_code" in payload or not "data" in payload:
		return
	#Make sure this is the correct object
	if not payload.rpc in ALLOWED_RPCS or not payload.op_code == OP_CODE:
		return

	call_deferred(payload.rpc, payload.data)


func remote_update_variable(data:Dictionary)-> void:
	if not "variable" in data or not "value" in data:
		return

	var variable:String = data.variable
	var value = data.value

	if variable in self:
		set(variable, value)
