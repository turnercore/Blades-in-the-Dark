extends Node

const DEFAULT_MAP_NOTE_ICON: = "res://Shared/Art/Icons/MapNoteIconTex.tres"
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

var save_game = SaveGame.new()

var username:String = "You" setget ,_get_username

#Store a reference to the current srd, used for looking up and displaying it in info
var srd:= {}

var game_state:String = "Free Play" setget _set_game_state

var is_game_setup: = false setget _set_is_game_setup
var needs_current_game_state: = false
var online: = false
var requesting_game_state: = false
var is_sending_data: = false

#Libraries of resources for in-game objects
var location_library: = Library.new()
var clock_library: = Library.new()
var pc_library: = Library.new()
var crew_playbook_resource:NetworkedResource setget _set_crew_playbook_resource
var active_pc: NetworkedResource setget _set_active_pc
#Data that stores the underlying data in the libraries. Is shared by the save_game
var crew_playbook: = {} setget _set_crew_playbook
var pc_playbooks: = []
var map:Dictionary = {} setget , _get_map
var clocks: = [] #Array of data
var roster:Array = []
var map_shortcuts:Array = []
#This is for undo stacks (later)
var recently_deleted: = []

#Signals
signal crew_changed
signal map_loaded(map)
signal roster_updated
signal map_shortcut_added
signal map_shortcut_removed
signal game_state_changed(game_state)
signal game_setup
signal game_state_loaded


#SETUP FUNCTIONS
func _ready() -> void:
	clock_library.library_name = "clocks"
	location_library.library_name = "locations"
	pc_library.library_name = "pcs"
	connect_to_signals()
	srd = load_srd_from_file(DEFAULT_SRD)

func connect_to_signals()-> void:
	clock_library.connect("resource_added", self, "_on_clock_resource_added")
	location_library.connect("resource_added", self, "_on_location_resource_added")
	pc_library.connect("resource_added", self, "_on_pc_resource_added")

	#LOCAL EVENTS
	Events.connect("map_created", self, "_on_map_created")
	Events.connect("map_changed", self, "_on_map_changed")
	Events.connect("map_removed", self, "_on_map_removed")
	GameSaver.connect("save_loaded", self, "_on_save_loaded")

	#Nakama Server Connection
	ServerConnection.connect("match_joined", self, "_on_match_joined")
	ServerConnection.connect("match_created", self, "_on_match_created")

#	#NETWORK EVENTS
	#Game State data
	NetworkTraffic.connect("gamedata_game_state_updated", self, "_on_game_state_updated")
	#PlayerPlaybooks
	NetworkTraffic.connect("gamedata_pc_playbook_created", self, "_on_pc_playbook_created_network")
	#Intial Game State Setup on Joining Match
	NetworkTraffic.connect("current_game_state_broadcast", self, "_on_current_game_state_broadcast")
	NetworkTraffic.connect("current_game_state_requested", self, "_on_current_game_state_requested")

func load_srd_from_file(srd_file_path:String)->Dictionary:
	var file = File.new()
	if not file.file_exists(srd_file_path):
		print("ERROR IN LOAD SRD FROM FILE GAMEDATA")
		print("unable to find file: " + srd_file_path)
	var result:int = file.open(srd_file_path, File.READ)
	var data:Dictionary = {}
	if result == OK:
		data = parse_json(file.get_as_text())
	else:
		print("Error opening srd file %s" % str(result))
	file.close()
	return data

func _on_current_game_state_broadcast(data, op_code:int)-> void:
	if not needs_current_game_state:
		print("Didn't request game state.")
		return
	match op_code:
		NetworkTraffic.OP_CODES.JOIN_MATCH_SRD_RECIEVED:
			if data is String:
				srd = load_srd_from_file(data)
			else:
				print("error with srd file path")
		NetworkTraffic.OP_CODES.JOIN_MATCH_MAP_RECEIVED:
			load_new_map(data)
		NetworkTraffic.OP_CODES.JOIN_MATCH_PLAYER_PLAYBOOK_RECIEVED:
			if not data is String:
				print("Incorrect player playbook data")
			else:
				pc_playbooks.append(pc_library.add(data))
		NetworkTraffic.OP_CODES.JOIN_MATCH_CREW_PLAYBOOK_RECEIVED:
			if not data is String:
				print("INCORRECTLY FORMATTED CREW DATA")
			else:
				self.crew_playbook = data
		NetworkTraffic.OP_CODES.JOIN_MATCH_CLOCKS_RECIEVED:
			clocks = data
		NetworkTraffic.OP_CODES.MATCH_DATA_ALL_SENT:
			is_game_setup = true
			needs_current_game_state = false
			requesting_game_state = false
			emit_signal("game_state_loaded")
		_:
			print("incorrect OP Code recieved in current match state broadcast")

func package_game_state()-> Dictionary:
	#Need to add clocks
	var data: = {
		"clocks" : clocks,
		"roster" : roster,
		"crew_playbook": crew_playbook,
		"map" : map,
		"srd" : DEFAULT_SRD
	}
	return data

func request_game_state()-> void:
	requesting_game_state = true
	ServerConnection.is_host = false
	var result: int = yield(NetworkTraffic.send_data_async(NetworkTraffic.OP_CODES.CURRENT_GAME_STATE_REQUESTED, ServerConnection.get_user_id()), "completed")
	if result != OK:
			print("error requesting game state")

func _on_current_game_state_requested(_user_id:String)-> void:
	print("game state requested from %s" % _user_id)
	if online and ServerConnection.is_host and not is_sending_data:
		is_sending_data = true
		var result:int
		var payload:Dictionary = package_game_state()
		print("Am host, sending game data")
		#send srd
		print("Sending srd")
		result = yield(NetworkTraffic.send_data_async(NetworkTraffic.OP_CODES.JOIN_MATCH_SRD_RECIEVED, payload.srd), "completed")
		if result != OK:
			print("ERROR unable to send srd")
			print(result)
			print(ServerConnection.error_message)
			return

		#Send each player playbook
		for playbook in payload.roster:
			print("sending pc playbook")
			result = yield(NetworkTraffic.send_data_async(NetworkTraffic.OP_CODES.JOIN_MATCH_PLAYER_PLAYBOOK_RECIEVED, playbook), "completed")
			if result != OK:
				print("ERROR unable to send player playbook")
				return

		#Send crew_playbook
		print("sending crew playbook")
		result = yield(NetworkTraffic.send_data_async(NetworkTraffic.OP_CODES.JOIN_MATCH_CREW_PLAYBOOK_RECEIVED, payload.crew_playbook), "completed")
		if result != OK:
			print("ERROR unable to send crew playbook")
			return

		#Send map (with locations?)
		print("sending map")
		result = yield(NetworkTraffic.send_data_async(NetworkTraffic.OP_CODES.JOIN_MATCH_MAP_RECEIVED, payload.map), "completed")
		if result != OK:
			print("ERROR unable to send map")
			return

		#Send clocks
		print("sending clocks")
		result = yield(NetworkTraffic.send_data_async(NetworkTraffic.OP_CODES.JOIN_MATCH_CLOCKS_RECIEVED, payload.clocks), "completed")
		if result != OK:
			print("ERROR unable to send gamestate")
			return

		#Send all done
		print("sending all done")
		result = yield(NetworkTraffic.send_data_async(NetworkTraffic.OP_CODES.MATCH_DATA_ALL_SENT, "<3"), "completed")
		if result != OK:
			print("ERROR unable to send ALL DONE .... weird.")
			return

		is_sending_data = false


#LOAD
func _on_save_loaded(save:SaveGame)->void:
	if not save.is_setup: save.setup(DEFAULT_SRD)

	save_game = save

	srd = save.srd if not save.srd.empty() else srd

	crew_playbook = save.crew_playbook
	var temp_lib: = Library.new()
	temp_lib.library_name = "crew"
	crew_playbook_resource = temp_lib.add(crew_playbook, false)

	roster = save.pc_playbooks
	for pc in roster:
		pc_library.add(pc, false)

	#Load clocks
	clocks = save.clocks
	clock_library.setup(clocks, true)
	emit_signal("clocks_updated")

	recently_deleted = save.recently_deleted

	map = save.map
	var locations:Dictionary = map.locations
	location_library.setup(locations, true)
	map_shortcuts = save.map_shortcuts
	emit_signal("map_loaded", map)

	self.is_game_setup = true

#SAVING
func save_game()-> void:
	for key in map.locations.keys():
		if map.locations[key].empty():
			map.locations.erase(key)
	GameSaver.save(save_game)

#PC PLAYBOOKS
func _on_pc_resource_added(resource:NetworkedResource)-> void:
	#Right now the locations are calling this with add_map_note and event signals, this can be reworked now
	pc_playbooks.append(resource.data)

func _on_pc_resource_removed(resource:NetworkedResource)-> void:
	pc_playbooks.erase(resource.data)

func _on_pc_playbook_created_network(data:Dictionary)-> void:
	roster.append(data)

#CREW PLAYBOOK
func _set_crew_playbook_resource(playbook:NetworkedResource)-> void:
	crew_playbook_resource = playbook
	crew_playbook= playbook.data
	save_game.crew_playbook = crew_playbook

func _set_crew_playbook(data:Dictionary)-> void:
	var playbook:NetworkedResource = NetworkedResource.new()
	playbook.setup(data)
	crew_playbook = data
	save_game.crew_playbook = crew_playbook
	crew_playbook_resource = playbook

#CLOCKS
func _on_clock_resource_added(clock:NetworkedResource)-> void:
	if not "id" in clock.data or clock.data.id == "":
		clock.data["id"] = clock.id
	clocks.append(clock.data)


#MAPS
func get_default_map()-> Dictionary:
	if map.empty():
		load_srd_from_file(DEFAULT_SRD)
		var default_srd_map:Dictionary = srd.default_maps["Duskvol"]
		create_map(default_srd_map)

	return map

func load_new_map(map_data)-> void:
	if map_data is int:
		change_map_to(map_data)
	elif map_data is Dictionary:
		map = map_data
	emit_signal("map_loaded", map)
	save_game()

func create_map(data:Dictionary, local: = true)-> void:
	if not "image_path" in data or not "map_name" in data:
		return
	var image_path:String = data.image_path
	var map_name:String = data.map_name

	if "map_index" in map:
		map = {}
		map.map_index = data.map_index if "map_index" in data else save_game.maps.size()
		map.locations = {}
		map.map_name = map_name
		map.image = image_path
		if not save_game.maps.has(map):
			save_game.maps.append(map)
		emit_signal("map_loaded", map)

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
	if index >= save_game.maps.size():
		print("index out of range")
		return
	save_game()
	map = save_game.maps[index]
	recently_deleted.append(location_library.clear())
	emit_signal("map_loaded", map)
	#Send over network

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

func _get_map()-> Dictionary:
	if map.empty() and not save_game.maps.empty():
		map = save_game.maps.front()
		save_game._map = map
	return map

#MAP SHORTCUTS
func add_map_shortcut(pos:Vector2)-> void:
	if not map_shortcuts.has(pos):
		map_shortcuts.append(pos)
	emit_signal("map_shortcut_added")

func remove_map_shortcut(pos:Vector2)-> void:
	if map_shortcuts.has(pos):
			map_shortcuts.erase(pos)
	emit_signal("map_shortcut_removed")


#LOCATIONS
func _on_location_resource_added(resource:NetworkedResource)-> void:
	#Right now the locations are calling this with add_map_note and event signals, this can be reworked now
	var pos:Vector2 = resource.get_vec2("pos")

	if pos in map.locations:
		print("ERROR Already have a note there" + str(pos))
		return
	else:
		map.locations[pos] = resource.data

func _on_location_resource_removed(resource:NetworkedResource)-> void:
	var pos:Vector2 = resource.get_vec2("pos")
	remove_map_note(pos)

func remove_map_note(pos: Vector2)-> void:
	map.locations.erase(pos)
	recently_deleted.append(location_library.delete(location_library.find_id("pos", pos)))


#GAME STATE
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

func _set_active_pc(pc_playbook: NetworkedResource)->void:
	active_pc = pc_playbook
	Events.emit_character_selected(pc_playbook)

func _get_username()-> String:
	var online_username = ServerConnection.get_self_username() if online else ""
	return online_username if online else username
