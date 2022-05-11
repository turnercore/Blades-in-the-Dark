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
const DEFAULT_SRD: = "res://srd/bitd_srd.json"
const CLOCK_SCENE: = preload("res://clocks/Clock.tscn")
const MAP_NOTE_SCENE: = preload("res://maps/MapNote.tscn")
const DEFAULT_MAP_DATA: = {

}

var save_game:SaveGame

var username:String = "You" setget ,_get_username

#Store a reference to the current srd, used for looking up and displaying it in info
var srd:= {} setget _set_srd, _get_srd

var game_state:String = "Free Play" setget _set_game_state
var player_color:Color = Color.coral
var is_game_setup: = false setget _set_is_game_setup
var needs_current_game_state: = false
var online: = false
var requesting_game_state: = false
var is_sending_data: = false

var crew_playbook_resource:NetworkedResource setget _set_crew_playbook_resource
var active_pc: NetworkedResource setget _set_active_pc
#Data that stores the underlying data in the libraries. Is shared by the save_game
var contacts: = {}
var factions: = {}
var crew_playbook: = {} setget _set_crew_playbook
var map:Dictionary = {} setget _set_map , _get_map
var clocks: = [] #Array of data
var roster:Array = []
var map_shortcuts:Array = []

#This is for undo delete (not yet implemented)
var recently_deleted: = []

#Libraries of resources for in-game objects
var location_library: = Library.new()
var region_library: = Library.new()
var clock_library: = Library.new()
var pc_library: = Library.new()
var contact_library: = Library.new()
var faction_library: = Library.new()
var cohort_library: = Library.new()

#Signals
signal crew_changed
signal map_loaded(map)
signal roster_updated
signal map_shortcut_added
signal map_shortcut_removed
signal game_state_changed(game_state)
signal game_setup
signal game_state_loaded

func _set_srd(new_srd:Dictionary)-> void:
	srd = new_srd
	#Setup libraries that are based on srd
	#Setup Faction Library
	factions = srd.factions
	faction_library.setup(srd.factions)
	#Setup Contact Library
	contacts = srd.contacts
	contact_library.setup(srd.contacts)


func _get_srd()-> Dictionary:
	if srd.empty():
		self.srd = load_srd_from_file(DEFAULT_SRD)
	return srd


#SETUP FUNCTIONS
func _ready() -> void:
	clock_library.library_name = "clocks"
	location_library.library_name = "locations"
	pc_library.library_name = "pcs"
	region_library.library_name = "regions"
	contact_library.library_name = "contacts"
	faction_library.library_name = "factions"
	cohort_library.library_name = "cohorts"
	connect_to_signals()

func connect_to_signals()-> void:
	clock_library.connect("resource_added", self, "_on_clock_resource_added")
	location_library.connect("resource_added", self, "_on_location_resource_added")
	region_library.connect("resource_added", self, "_on_region_resource_added")
	pc_library.connect("resource_added", self, "_on_pc_resource_added")

	#LOCAL EVENTS
	Events.connect("map_changed", self, "_on_map_changed")
	GameSaver.connect("save_loaded", self, "_on_save_loaded")

	#Nakama Server Connection
	ServerConnection.connect("match_joined", self, "_on_match_joined")
	ServerConnection.connect("match_created", self, "_on_match_created")

#	#NETWORK EVENTS
	#Game State data
	NetworkTraffic.connect("gamedata_game_state_updated", self, "_on_game_state_updated")
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
			load_map(data)
		NetworkTraffic.OP_CODES.JOIN_MATCH_PLAYER_PLAYBOOK_RECIEVED:
			if not data is String:
				print("Incorrect player playbook data")
			else:
				roster.append(pc_library.add(data))
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

#SAVEGAME
func create_save(save:SaveGame)-> void:
	self.save_game = save
	contacts = save_game.contacts
	contact_library.burn_down()
	factions = save_game.factions
	faction_library.burn_down()
	crew_playbook = save_game.crew_playbook
	roster = save_game.pc_playbooks
	pc_library.burn_down()
	map = save_game.map
	clocks = save_game.clocks
	clock_library.burn_down()
	map_shortcuts = save_game.map_shortcuts



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
	roster.append(resource.data)

func _on_pc_resource_removed(resource:NetworkedResource)-> void:
	roster.erase(resource.data)

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
func load_map(data:Dictionary)-> void:
	if not "locations" in data or not "map_regions" in data: return

	if map != data:
		self.map = data
		return
	for location in data.locations:
		var resource:NetworkedResource = location_library.add(location)
		if not resource.is_connected("deleted", self, "_on_location_resource_removed"):
			resource.connect("deleted", self, "_on_location_resource_removed")
	for region in data.map_regions:
		var resource:NetworkedResource = region_library.add(region)
		if not resource.is_connected("deleted", self, "_on_region_resource_removed"):
			resource.connect("deleted", self, "_on_region_resource_removed")
	emit_signal("map_loaded", map)

func create_map(data:Dictionary)-> void:
	pass

func change_map_to(index:int)-> void:
	if index >= save_game.maps.size() or index < 0:
		print("index out of range")
		return
	save_game()
	save_game.map = save_game.maps[index]
	self.map = save_game.map


func _set_map(new_map:Dictionary)-> void:
	map = new_map
	location_library.unload()
	region_library.unload()
	load_map(new_map)


func _on_map_created(image_path: String, map_name: String)-> void:
	var data: = DEFAULT_MAP_DATA.duplicate(true)
	data.image = image_path
	data.name = map_name
	create_map(data)

func _on_map_changed(index:int)-> void:
	if index < save_game.maps.size() and index > -1 and map.index != index:
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
		self.map = save_game.maps.front()
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

func _on_region_resource_added(resource:NetworkedResource)-> void:
	map.map_regions.append(resource.data)

func _on_region_resource_removed(resource:NetworkedResource)-> void:
	map.map_regions.erase(resource.data)

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

func _set_active_pc(value: NetworkedResource)->void:
	active_pc = value
	Events.emit_character_selected(active_pc)

func _get_username()-> String:
	var online_username = ServerConnection.get_self_username() if online else ""
	return online_username if online else username
