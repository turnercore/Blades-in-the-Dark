extends Node

const DEFAULT_MAP: = "duskfull"
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

var save_game:SaveGame

var players: = {}
var local_player:Player setget _set_local_player, _get_local_player
var settings:Dictionary = {}

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
var maps: = {}
var cohorts: = {}
var map setget _set_map, _get_map
var crew_playbook: = {} setget _set_crew_playbook
var clocks: = {} #Array of data
var roster: = {}
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
var map_library: = Library.new()

#Signals
signal crew_changed
signal map_loaded(map)
signal roster_updated
signal map_shortcut_added
signal map_shortcut_removed
signal game_state_changed(game_state)
signal game_setup
signal game_state_loaded
signal save_loaded

func _set_srd(new_srd:Dictionary)-> void:
	srd = new_srd
	#Setup libraries that are based on srd
	#Setup Faction Library
	faction_library.setup(srd.factions)


func _get_srd()-> Dictionary:
	if srd.empty():
		self.srd = load_srd_from_file(DEFAULT_SRD)
	return srd


#SETUP FUNCTIONS
func _ready() -> void:
	setup_player()
	GameSaver.connect("save_loaded", self, "_on_save_loaded")
	yield(self, "save_loaded")
	construct_libraries()
	connect_to_signals()


func setup_player()-> void:
	self.local_player = Player.new()
	local_player.username = "You"
	local_player.color = Color.coral
	local_player.id = ServerConnection.get_user_id() if online else "Offline"


func construct_libraries()-> void:
	clock_library.library_name = "clocks"
	location_library.library_name = "locations"
	pc_library.library_name = "pcs"
	region_library.library_name = "regions"
	contact_library.library_name = "contacts"
	faction_library.library_name = "factions"
	cohort_library.library_name = "cohorts"
	map_library.library_name = "maps"


func connect_to_signals()-> void:
	#Library Signals
	clock_library.connect("resource_added", self, "_on_clock_resource_added")
	location_library.connect("resource_added", self, "_on_location_resource_added")
	region_library.connect("resource_added", self, "_on_region_resource_added")
	pc_library.connect("resource_added", self, "_on_pc_resource_added")
	map_library.connect("resource_added", self, "_on_map_resource_added")
	contact_library.connect("resource_added", self, "_on_contact_resource_added")
	faction_library.connect("resource_added", self, "_on_faction_resource_added")
	cohort_library.connect("resource_added", self, "_on_cohort_resource_added")

	#LOCAL EVENTS
	Events.connect("map_changed", self, "_on_map_changed")

	#Nakama Server Connection
	ServerConnection.connect("match_joined", self, "_on_match_joined")
	ServerConnection.connect("match_created", self, "_on_match_created")
	ServerConnection.connect("user_joined", self, "_on_user_joined")
	ServerConnection.connect("user_left", self, "_on_user_left")

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
	settings = save_game.settings
	emit_signal("save_loaded")

#LOAD
func _on_save_loaded(save:SaveGame)->void:
	print('loading save')
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

	map = save.map if save.map else ""
	maps = save.maps
	for map_id in maps:
		var selected = maps[map_id]
		map_library.add(selected)
	var locations:Dictionary = self.map.find("locations")
	var regions:Dictionary = self.map.find("regions")
	for region_id in regions:
		var region:Dictionary = regions[region_id]
		region_library.add(region)

	for location_id in locations:
		var location:Dictionary = locations[location_id]
		location_library.add(location)

	location_library.setup(locations, true)
	map_shortcuts = save.map_shortcuts

	emit_signal("map_loaded", self.map)

	self.is_game_setup = true
	emit_signal("save_loaded")

#SAVING
func save_game()-> void:
	#These should be connected already, but in case they aren't this makes sure
	save_game.contacts = contacts
	save_game.factions = factions
	save_game.crew_playbook = crew_playbook
	save_game.pc_playbooks = roster
	save_game.map = map
	save_game.clocks = clocks
	save_game.map_shortcuts = map_shortcuts
	save_game.settings = settings
	save_game.srd = srd
	GameSaver.save(save_game)

#PC PLAYBOOKS
func _on_pc_resource_added(resource:NetworkedResource)-> void:
	#Right now the locations are calling this with add_map_note and event signals, this can be reworked now
	roster[resource.id] = resource.data
	save_game()

func _on_pc_resource_removed(resource:NetworkedResource)-> void:
	pc_library.delete_id(resource.id)
	roster.erase(resource.id)
	save_game()

func _on_pc_playbook_created_network(data:Dictionary)-> void:
	pc_library.add(data)
	roster[data.id] = data
	save_game()


#CONTACTS
func _on_contact_resource_added(contact_resource:NetworkedResource)-> void:
	if not contacts.has(contact_resource.id):
		contacts[contact_resource.id] = contact_resource.data
	save_game()

#FACTIONS
func _on_faction_resource_added(faction_resource:NetworkedResource)-> void:
	if not factions.has(faction_resource.id):
		factions[faction_resource.id] = faction_resource.data
	save_game()

#COHORTS
func _on_cohort_resource_added(cohort_resource:NetworkedResource)-> void:
	if not cohorts.has(cohort_resource.id):
		cohorts[cohort_resource.id] = cohort_resource.data
	save_game()

#CREW PLAYBOOK
func _set_crew_playbook_resource(playbook:NetworkedResource)-> void:
	crew_playbook_resource = playbook
	crew_playbook= playbook.data
	save_game.crew_playbook = crew_playbook
	save_game()

func _set_crew_playbook(data:Dictionary)-> void:
	var playbook:NetworkedResource = NetworkedResource.new()
	playbook.setup(data)
	crew_playbook = data
	save_game.crew_playbook = crew_playbook
	crew_playbook_resource = playbook
	save_game()

#CLOCKS
func _on_clock_resource_added(clock:NetworkedResource)-> void:
	if not "id" in clock.data or clock.data.id == "":
		clock.data["id"] = clock.id
	if not clocks.has(clock.id):
		clocks[clock.id] = clock.data
	save_game()


#MAPS
func change_map_to(id:String)-> void:
	if not maps.has(id):
		print("gamedata: Could not find map in map database")
		return
	map = id
	save_game.map = id
	location_library.unload()
	region_library.unload()
	var map_resource:NetworkedResource = self.map
	var locations:Dictionary = map_resource.find("locations")
	var regions:Dictionary = map_resource.find("regions")
	for key in locations:
		var location = locations[key]
		location_library.add(location)
	for key in regions:
		var region = regions[key]
		region_library.add(region)
	save_game()


func _on_map_created(image_path: String, map_name: String)-> void:
	print("gamedata: Mqp creation not ready yet")
	save_game()
#	var data: = {}
#	data.image = image_path
#	data.name = map_name
#	create_map(data)


func create_map(data:Dictionary)-> void:
	pass


func _on_map_changed(id:String)-> void:
	change_map_to(id)


func _on_map_removed(id:String)->void:
	maps.erase(id)
	map_library.delete_id(id, false)


func _get_map():
	if map:
		return map_library.get(map)
	else:
		var map_resource:NetworkedResource = map_library.get_first()
		if not map_resource:
			return null
		self.map = map_resource.id
		return map_resource


func _set_map(map_id:String)-> void:
	if not maps.has(map_id):
		print("gamedata: map id not found in maps")
		return
	map = map_id
	location_library.unload()
	region_library.unload()
	change_map_to(map_id)


func _on_map_resource_added(map_resource:NetworkedResource)-> void:
	if not maps.has(map_resource.id):
		maps[map_resource.id] = map_resource.data
	save_game()


#MAP SHORTCUTS
func add_map_shortcut(pos:Vector2)-> void:
	if not map_shortcuts.has(pos):
		map_shortcuts.append(pos)
	save_game()
	emit_signal("map_shortcut_added")

func remove_map_shortcut(pos:Vector2)-> void:
	if map_shortcuts.has(pos):
			map_shortcuts.erase(pos)
	save_game()
	emit_signal("map_shortcut_removed")


#LOCATIONS
func _on_location_resource_added(resource:NetworkedResource)-> void:
	#Right now the locations are calling this with add_map_note and event signals, this can be reworked now
	if maps.has(resource.find("map")):
		if not maps[resource.find("map")].locations.has(resource.id):
			maps[resource.find("map")].locations[resource.id] = resource.data
			save_game()
		else:
			print("gamedata: region already found in map....")
	else:
		print("gamedata: Could not find map to add region to")


func _on_location_resource_removed(resource:NetworkedResource)-> void:
	var map_resource:NetworkedResource = self.map
	map_resource.remove("locations.%s" % resource.id)
	save_game()


func _on_region_resource_added(resource:NetworkedResource)-> void:
	if maps.has(resource.find("map")):
		if not maps[resource.find("map")].regions.has(resource.id):
			maps[resource.find("map")].regions[resource.id] = resource.data
			save_game()
		else:
			print("gamedata: region already found in map....")
	else:
		print("gamedata: Could not find map to add region to")


func _on_region_resource_removed(resource:NetworkedResource)-> void:
	var map_resource:NetworkedResource = self.map
	map_resource.remove("regions.%s" % resource.id)
	save_game()


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
			if maps.has(data.id):
				change_map_to(data.id)
			else:
				create_map(data)
		NetworkTraffic.OP_CODES.JOIN_MATCH_PLAYER_PLAYBOOK_RECIEVED:
			roster[data.id] = data
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
		"map" : self.map.data,
		"srd" : DEFAULT_SRD,
		"contacts" : contacts,
		"cohorts" : cohorts
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

		#Send map (this also sends locations and regions)
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

		#Send cohorts

		#Send all done
		print("sending all done")
		result = yield(NetworkTraffic.send_data_async(NetworkTraffic.OP_CODES.MATCH_DATA_ALL_SENT, "<3"), "completed")
		if result != OK:
			print("ERROR unable to send ALL DONE .... weird.")
			return

		is_sending_data = false


func _on_user_left(user)-> void:
	var player: = Player.new()
	player.username = user.username
	player.id = user.user_id
	if players.has(user.user_id):
		players.erase(user.user_id)


func _on_user_joined(user)-> void:
	var player: = Player.new()
	player.username = user.username
	player.id = user.user_id
	if not players.has(player.id):
		players[player.id] = player


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


func _set_local_player(value:Player)-> void:
	local_player = value
	players["local"] = value


func _get_local_player()-> Player:
	return players["local"]


class Player:
	var color:Color = Color.blue
	var id:String setget , _get_id
	var username:String setget , _get_username
	var local: = false

	func _get_id()-> String:
		if local and GameData.online:
			return ServerConnection.get_user_id()
		else:
			return id

	func _get_username()-> String:
		if local and not GameData.online:
			return "You"
		else:
			return username
