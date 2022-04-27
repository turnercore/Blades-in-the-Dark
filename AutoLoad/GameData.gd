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

const DEFAULT_SRD: = "res://srd/default_srd.json"
const CLOCK_SCENE: = preload("res://clocks/Clock.tscn")
const MAP_NOTE_SCENE: = preload("res://maps/MapNote.tscn")

export (Resource) var crew_playbook = null

#This should be updated to remove the "roster" checks and just be an Array itself
export (Array) var roster:Array = []
export (Resource) var save_game = SaveGame.new() setget _set_save_game

#The active character (for this player)
var active_pc: PlayerPlaybook setget _set_active_pc
#Store a reference to the current srd, used for looking up and displaying it in info
var srd:= {}
#This could probably be reworked into an array
var clocks: = []

var map:Dictionary = {
	"map_index": 0,
	"map_name": "Duskvol",
	"image": null,
	"notes": {}, #Dict with POS : MapNote
	"srd_notes": {}
	} setget _set_map

#ARRAY OF MAP NOTES a map note is a location
var map_shortcuts:Array = []
var clocks_being_saved: = false

var game_state:String = "Free Play" setget _set_game_state

var is_game_setup: = false setget _set_is_game_setup
var needs_current_game_state:bool = false
var online: = false

#Signals
signal crew_changed
signal clocks_updated

signal map_loaded(map)
#I think these are unused
signal roster_updated
signal clocks_free
signal map_shortcut_added
signal map_shortcut_removed
signal map_shortcuts_updated
signal game_state_changed(game_state)
signal game_setup

#SETUP FUNCTIONS
func _ready() -> void:
	connect_to_signals()

	srd = load_srd_from_file(DEFAULT_SRD)

	for playbook in roster:
		if not playbook is PlayerPlaybook: continue
		if not playbook.is_connected("changed", self, "_on_playbook_updated"):
			playbook.connect("changed", self, "_on_playbook_updated", [playbook])
		if not playbook.is_connected("property_changed", self, "_on_playbook_property_changed"):
			playbook.connect("property_changed", self, "_on_playbook_property_changed", [playbook])

#Make sure anything being stored under this Node is not visible
func _process(_delta: float) -> void:
	for child in get_children():
		if child.visible:
			child.visible = false


func connect_to_signals()-> void:
	Events.connect("clock_updated", self,"_on_clock_updated")
	Events.connect("clock_removed", self, "_on_clock_removed")
	Events.connect("map_created", self, "_on_map_created")
	Events.connect("map_changed", self, "_on_map_changed")
	Events.connect("map_removed", self, "_on_map_removed")
	Events.connect("map_note_updated", self, "_on_map_note_updated", [true])
	Events.connect("map_note_created", self, "_on_map_note_created", [true])
	Events.connect("map_note_removed", self, "_on_map_note_removed", [true])

	#Nakama Server Connection
	ServerConnection.connect("match_joined", self, "_on_match_joined")
	ServerConnection.connect("match_created", self, "_on_match_created")

	#Data that comes from the network
	#Location Data
	NetworkTraffic.connect("gamedata_location_created", self, "_on_map_note_created", [false])
	NetworkTraffic.connect("gamedata_location_removed", self, "_on_map_note_removed", [false])
	NetworkTraffic.connect("gamedata_location_updated", self, "_on_map_note_updated", [false])
	#Game State data
	NetworkTraffic.connect("gamedata_game_state_updated", self, "_on_game_state_updated")
	#Playbooks
	NetworkTraffic.connect("gamedata_playbook_removed", self, "_on_playbook_removed")
	NetworkTraffic.connect("gamedata_playbook_updated", self, "_on_network_playbook_updated")
	#PlayerPlaybooks
	NetworkTraffic.connect("gamedata_pc_playbook_created", self, "_on_pc_playbook_created")
	#CrewPlaybook
	NetworkTraffic.connect("gamedata_crew_playbook_created", self, "_on_crew_playbook_created")
	#Clock Data
	NetworkTraffic.connect("gamedata_clock_created", self, "_on_gamedata_clock_created")
	NetworkTraffic.connect("gamedata_clock_removed", self, "_on_gamedata_clock_removed")
	NetworkTraffic.connect("gamedata_clock_updated", self, "_on_gamedata_clock_updated")
	#Intial Game State Setup on Joining Match
	NetworkTraffic.connect("inital_game_state_recieved", self, "_on_intial_game_state_recieved")
	NetworkTraffic.connect("current_game_state_requested", self, "_on_current_game_state_requested")

	if not GameSaver.is_connected("save_loaded", self, "_on_save_loaded"):
		GameSaver.connect("save_loaded", self, "_on_save_loaded")
	if not GameSaver.is_connected("crew_loaded", self, "_on_crew_loaded"):
		GameSaver.connect("crew_loaded", self, "_on_crew_loaded")
	if not GameSaver.is_connected("roster_loaded", self, "_on_roster_loaded"):
		GameSaver.connect("roster_loaded", self, "_on_roster_loaded")

func load_srd_from_file(srd_file_path:String)->Dictionary:
	var file = File.new()
	if not file.file_exists(srd_file_path):
		print("unable to find file: " + srd_file_path)
	var result:int = file.open(srd_file_path, File.READ)
	var data:Dictionary = {}
	if result == OK:
		data = parse_json(file.get_as_text())
	else:
		print("Error opening srd file %s" % str(result))
	file.close()
	return data

func _on_intial_game_state_recieved(data:Dictionary)->void:
	if needs_current_game_state:
		#Setup Clocks
		clocks.clear()
		for clock_data in data.clocks:
			var new_clock:Clock = CLOCK_SCENE.instance()
			add_child(new_clock)
			new_clock.setup_from_data(clock_data)
		#Setup CrewPlaybook
		crew_playbook = CrewPlaybook.new()
		if data.crew_playbook is String:
			crew_playbook.load_from_json(data.crew_playbook)
		else:
			print("error, crew playbook was incorrectly formatted to load from json")
		#Setup Roster
		for playbook in data.roster:
			var player: = PlayerPlaybook.new()
			player.load_from_json(playbook)
		#Setup Map
		map = data.map
		#Locations
		for location in data.locations:
			add_map_note(location)
		#Srd
		srd = data.srd
		is_game_setup = true
		needs_current_game_state = false

func package_game_state()-> Dictionary:
	var data: = {}
	data["clocks"] = []
	for clock in clocks:
		var clock_data:Dictionary = clock.package()
		data.clocks.append(clock_data)
	data["roster"] = []
	for playbook in roster:
		var playbook_json:String = playbook.package_as_json()
		data.roster.append(playbook_json)
	data["crew_playbook"] = crew_playbook.package_as_json()
	data["map"] = map
	data["srd"] = srd
	return data

func request_game_state()-> void:
	if needs_current_game_state:
		var result: int = yield(NetworkTraffic.send_data_async(NetworkTraffic.OP_CODES.CURRENT_GAME_STATE_REQUESTED, ServerConnection.get_user_id()), "completed")
		if result != OK:
			print("error requesting game state")

func _on_current_game_state_requested(_user_id:String)-> void:
	print("game state requested from someone")
	if online and ServerConnection.is_connected_to_server and ServerConnection.is_host:
		var result:int = yield(NetworkTraffic.send_data_async(NetworkTraffic.OP_CODES.CURRENT_GAME_STATE_BROADCAST, package_game_state()), "completed")
		if result != OK:
			print("ERROR unable to send gamestate")
	else:
		print("not host, ignoring request")

#CLOCKS
func _on_gamedata_clock_created(clock:Clock)-> void:
	add_clock(clock, false)
	emit_signal("clocks_updated")

func _on_gamedata_clock_removed(clock_id:String)-> void:
	remove_clock(clock_id, false)
	emit_signal("clocks_updated")

func _on_gamedata_clock_updated(clock:Clock)-> void:
	update_clock(clock, false)
	emit_signal("clocks_updated")

func get_clocks()-> Array:
	if clocks_being_saved:
		yield(self, "clocks_free")
	clocks = save_game.clocks
	return clocks

func add_clock(clock:Clock, local: = true)-> void:
	clocks.append(clock)
	if online and local:
		print("Sending shiny new clock over the network to our lovely friends")
		var result:int = yield(NetworkTraffic.send_data_async(NetworkTraffic.OP_CODES.GAMEDATA_CLOCK_CREATED, clock.package()), "completed")
		if result != OK:
			print("ERROR SENDING UPDATED CLOCK DATA ACROSS NETWORK")
	save_clocks()

func _on_clock_updated(clock:Clock)->void:
	update_clock(clock)

func update_clock(clock:Clock, local: = true)-> void:
	if online and local:
		var result:int = yield(NetworkTraffic.send_data_async(NetworkTraffic.OP_CODES.GAMEDATA_CLOCK_UPDATED, clock.package()), "completed")
		if result != OK:
			print("ERROR SENDING UPDATED CLOCK DATA ACROSS NETWORK")
	save_clocks()

func _on_clock_removed(clock_id:String)-> void:
	remove_clock(clock_id)

func remove_clock(clock_id:String, local: = true)-> void:
	for clock in clocks:
		if clock.id == clock_id:
			clocks.erase(clock_id)
			break
	if online and local:
		var result:int = yield(NetworkTraffic.send_data_async(NetworkTraffic.OP_CODES.GAMEDATA_CLOCK_REMOVED, clock_id), "completed")
		if result != OK:
			print("ERROR SENDING REMOVED CLOCK DATA ACROSS NETWORK")
	save_clocks()

#SAVE GAME
func _on_save_loaded(save:SaveGame)->void:
	self.save_game = save
	self.srd = save.srd_data

	#Load clocks
	clocks.clear()
	for clock_data in save.clocks:
		var new_clock:Clock = CLOCK_SCENE.instance()
		new_clock.setup_from_data(clock_data)
		clocks.append(new_clock)
	emit_signal("clocks_updated")

	if not save.is_setup: save.setup_srd_maps()

	self.map = save._map.duplicate(true) if save._map else save.maps[0].duplicate(true)
	map.notes.clear()
	for pos in save._map.notes:
		print("Setting up a pos from _map.notes " + str(pos))
		var new_location:MapNote = MAP_NOTE_SCENE.instance()
		add_child(new_location)
		new_location.setup_from_data(save._map.notes[pos])
		map.notes[pos] = new_location
	for pos in save._map.srd_notes:
		print("Setting up a pos from _map.srdnotes " + str(pos))
		var new_location:MapNote = MAP_NOTE_SCENE.instance()
		add_child(new_location)
		new_location.setup_from_data(save._map.srd_notes[pos])
		map.notes[pos] = new_location

	self.map_shortcuts = save.map_shortcuts
	emit_signal("map_shortcuts_updated")
	emit_signal("map_loaded")
	self.is_game_setup = true

func _set_save_game(new_save: SaveGame)-> void:
	if not new_save.is_setup: new_save.setup_save()
	clocks = new_save.clocks
	map = new_save._map
	save_game = new_save

#SAVING FUNCTIONS
func save_map()-> void:
	var map_previously_existed:= false
	#Package map to save
	var formatted_map_notes: = {}
	var save_map: = map.duplicate(true)

	for pos in map.notes:
		var ref = weakref(map.notes[pos])
		if not ref:
			continue
		else:
			formatted_map_notes[pos] = map.notes[pos].package()

	save_map.notes = formatted_map_notes

	for saved_map in save_game.maps:
		if save_map.map_name and saved_map.map_name:
			if save_map.map_name == saved_map.map_name:
				#update the map if found
				var index:int = save_game.maps.find(saved_map)
				save_game.maps[index] = save_map
				map_previously_existed = true

	if not map_previously_existed:
		save_game.maps.append(save_map)

	save_game._map = save_map

func save_all()-> void:
	var data: = []
	save_clocks()
	save_map()
	data = [save_game, crew_playbook, roster]
	GameSaver.save_all(data)

func save_clocks()->void:
	self.clocks_being_saved = true
	var clock_data_array: = []

	for clock in clocks:
		clock_data_array.append(clock.package())
	save_game.clocks = clock_data_array
	self.clocks_being_saved = false

#PLAYBOOKS
func _on_pc_playbook_created(playbook:PlayerPlaybook)-> void:
	if not playbook in roster:
		add_pc_to_roster(playbook, false)

func _on_playbook_removed(playbook:Playbook)-> void:
	if playbook is PlayerPlaybook:
		remove_pc_from_roster(playbook)
	elif playbook is CrewPlaybook:
		print("I can't unload a crew in the middle of the game yet...error")
	else:
		print("Playbook was base Playbook type...")

func _on_crew_playbook_created(playbook:CrewPlaybook)-> void:
	crew_playbook = playbook

func _on_network_playbook_updated(playbook_id:String, playbook_type:String, playbook_field:String, updated_value)-> void:
	if playbook_type.to_lower() == "player":
		for playbook in roster:
			if playbook.id == playbook_id:
				update_pc_playbook(playbook, playbook_field, updated_value)

func load_roster(playbooks:Array)-> void:
	for playbook in playbooks:
		if not roster.has(playbook):
			roster.append(playbook)

	for playbook in playbooks:
		if not playbook is PlayerPlaybook: continue
		if not playbook.is_connected("changed", self, "_on_playbook_updated"):
			playbook.connect("changed", self, "_on_playbook_updated", [playbook])

func add_pc_to_roster(playbook:PlayerPlaybook, local: = true)-> void:
	roster.append(playbook)
	if not playbook.is_connected("property_changed", self, "_on_playbook_property_changed"):
		playbook.connect("property_changed", self, "_on_playbook_property_changed", [playbook])
	if online and local:
		var result:int = yield(NetworkTraffic.send_data_async(NetworkTraffic.OP_CODES.GAMEDATA_PC_PLAYBOOK_CREATED, playbook.package_as_json()), "completed")
		if result != OK:
			print(ServerConnection.error_message)
			print(result)
	elif online and not local:
		emit_signal("roster_updated")
	GameSaver.save(playbook)

func update_pc_playbook(playbook:PlayerPlaybook, field:String, value)-> void:
	if playbook.find(field) != value:
		playbook.save(field, value)

func remove_pc_from_roster(playbook:PlayerPlaybook)-> void:
	roster.erase(playbook)
	GameSaver.erase(playbook)

func _on_roster_loaded(playbooks:Array)-> void:
	load_roster(playbooks)

func _on_playbook_property_changed(field:String, playbook:Playbook)-> void:
	if online:
		var payload: = {
		"id": playbook.id,
		"field": field,
		"value": playbook.find(field),
		"type": playbook.PLAYBOOK_TYPE
		}
		yield(NetworkTraffic.send_data_async(NetworkTraffic.OP_CODES.GAMEDATA_PLAYBOOK_UPDATED, payload), "completed")

func _on_playbook_updated(playbook:Playbook)->void:
	GameSaver.save(playbook)

func _on_crew_loaded(crew: CrewPlaybook)-> void:
	load_crew(crew)

func load_crew(crew:CrewPlaybook)-> void:
	if crew_playbook:
		if crew_playbook.is_connected("changed", self, "_on_playbook_updated"):
			crew_playbook.disconnect("changed", self, "_on_playbook_updated")
	if not crew.is_connected("changed", self, "_on_playbook_updated"):
		crew.connect("changed", self, "_on_playbook_updated",[crew])
	crew_playbook = crew

#MAPS
func create_map(data:Dictionary, local: = true)-> void:
	if not "image_path" in data or not "map_name" in data:
		return
	var image_path:String = data.image_path
	var map_name:String = data.map_name

	if "map_index" in map:
		map.map_index = data.map_index if "map_index" in data else save_game.maps.size()
		map.notes = {}
		map.map_name = map_name
		map.image = image_path
		if not save_game.maps.has(map):
			save_game.maps.append(map)
		emit_signal("map_loaded")

	if online and local:
		var result:int = yield(NetworkTraffic.send_data_async(NetworkTraffic.OP_CODES.GAMEDATA_MAP_CREATED, map), "completed")
		if result != OK:
			print("ERROR sending newly created map")

func _on_map_created(image_path: String, map_name: String)-> void:
	var data: = {
		"image_path": image_path,
		"map_name": map_name
	}
	create_map(data)


func change_map_to(index:int)-> void:
	#Save the current map
	save_map()
	#clear the old locations
	for location in map.notes:
		map.notes[location].queue_free()

	#Get the new map setup
	map = save_game.maps[index].duplicate(true)
	save_game._map = save_game.maps[index]
	map.notes = {}
	#Get new nodes
	for pos in save_game.maps[index].notes:
		var new_location:MapNote = MAP_NOTE_SCENE.instance()
		new_location.setup_from_data(save_game.maps[index].notes[pos])
		add_child(new_location)
		map.notes[pos] = new_location

	emit_signal("map_loaded")

func _on_map_changed(index:int)-> void:
	if index < save_game.maps.size() and index > -1:
		change_map_to(index)
	else:
		print("Error map index out of range")

func _on_map_removed(index:int)->void:
	if index < save_game.maps.size() and index > -1:
		save_game.maps.remove(index)
	else:
		print("Error map index out of range")

func _set_map(value:Dictionary)-> void:
	map = value

#MAP SHORTCUTS
func add_map_shortcut(note:MapNote)-> void:
	if not map_shortcuts.has(note.pos):
		map_shortcuts.append(note.pos)
	emit_signal("map_shortcut_added")


func remove_map_shortcut(note:MapNote)-> void:
	if map_shortcuts.has(note.pos):
			map_shortcuts.erase(note.pos)
	emit_signal("map_shortcut_removed")


#LOCATIONS
#I think this doesn't work
func remove_map_note(note: Vector2)-> void:
	var grid_pos: = Globals.convert_to_grid(note)
	if map.notes.has(grid_pos):
		remove_map_shortcut(map.notes.get(grid_pos))
		map.notes.erase(grid_pos)
	save_map()


func add_map_note(data)-> void:
	if data is Dictionary:
		var pos:Vector2 = data.pos if data.pos is Vector2 else Globals.str_to_vec2(data.pos)
		if not "notes" in map:
			map["notes"] = {}
		if pos in map.notes: return
		var new_map_note: = MAP_NOTE_SCENE.instance()
		add_child(new_map_note)
		new_map_note.setup_from_data(data)
		map.notes[pos] = new_map_note
	elif data is MapNote:
		if map.notes.has(data.pos):
			return
		else:
			map.notes[data.pos] = data
	save_map()


func update_map_note(location:MapNote):
	if not location.pos in map.notes:
		print("error somehow couldn't find note in map \n location pos: %s || map.notes: %s" % [str(location.pos), str(map.notes)])
		return
	#Check to see if the position has been updated
	for pos in map.notes.keys():
		if map.notes[pos] == location:
			if pos != location.pos:
				map.notes[location.pos] = location
				map.notes.erase(pos)
	save_map()


func _on_map_note_created(note:MapNote, local:bool)-> void:
	add_map_note(note)
	#If it's a local request, make sure to update the rest of the people
	if online and local:
		print("SENDING MAP NOTE")
		yield(NetworkTraffic.send_data_async(NetworkTraffic.OP_CODES.GAMEDATA_LOCATION_CREATED, note.package()), "completed")


func _on_map_note_updated(note: MapNote, local:bool)-> void:
	update_map_note(note)
	if online and local:
		yield(NetworkTraffic.send_data_async(NetworkTraffic.OP_CODES.GAMEDATA_LOCATION_UPDATED, note.package()), "completed")

func _on_map_note_removed(note: Vector2, local:bool)-> void:
	remove_map_note(note)
	if online and local:
		yield(NetworkTraffic.send_data_async(NetworkTraffic.OP_CODES.GAMEDATA_LOCATION_REMOVED, note), "completed")

func _on_game_state_updated(value:String)-> void:
	self.game_state = value


func _set_game_state(value:String)-> void:
	game_state = value
	emit_signal("game_state_changed", value)


func _set_is_game_setup(value:bool)-> void:
	is_game_setup = value
	if is_game_setup:
		emit_signal("game_setup")


#Multiplayer Functions to keep data the same between everyone
func _on_match_joined(_match = null)-> void:
	self.online = true
	if not ServerConnection.is_host:
		needs_current_game_state = true
		request_game_state()


func _on_match_created()-> void:
	self.online = true
	needs_current_game_state = false

func remote_update_variable(data:Dictionary)-> void:
	if not "variable" in data or not "value" in data:
		return

	var variable:String = data.variable
	var value = data.value

	if variable in self:
		set(variable, value)


func _set_active_pc(playbook: PlayerPlaybook)->void:
	active_pc = playbook
	Events.emit_character_selected(playbook)

func _set_clocks_being_saved(value: bool)-> void:
	if not value: emit_signal("clocks_free")
	clocks_being_saved = value
