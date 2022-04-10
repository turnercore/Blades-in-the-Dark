extends Node

export (Resource) var crew_playbook = null
export (Dictionary) var pc_playbooks:Dictionary
#{
	#Has player ID as key
	#"player_id": PlayerPlaybook.new(),
	#Roster is an array of inactive playbooks
	#"roster": [
#		PlayerPlaybook,
#		PlayerPlaybook
	#]
#}

export (Resource) var save_game = SaveGame.new() setget _set_save_game
var srd
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
#		"is_secret": false
#		}
}

var map:Dictionary
var clocks_being_saved: = false

signal clocks_free
signal crew_changed
signal pc_playbooks_changed
signal clocks_loaded(clocks)
signal map_loaded(map)


func _ready() -> void:
	connect_to_signals()

	if pc_playbooks and "roster" in pc_playbooks:
		for playbook in pc_playbooks:
			if not playbook is PlayerPlaybook: continue
			if not playbook.is_connected("changed", self, "_on_playbook_updated"):
				playbook.connect("changed", self, "_on_playbook_updated", [playbook])


func connect_to_signals()-> void:
	Events.connect("clock_updated", self,"_on_clock_updated")

	if not GameSaver.is_connected("save_loaded", self, "_on_save_loaded"):
		GameSaver.connect("save_loaded", self, "_on_save_loaded")
	if not GameSaver.is_connected("crew_loaded", self, "_on_crew_loaded"):
		GameSaver.connect("crew_loaded", self, "_on_crew_loaded")
	if not GameSaver.is_connected("pc_playbooks_loaded", self, "_on_pc_playbooks_loaded"):
		GameSaver.connect("pc_playbooks_loaded", self, "_on_pc_playbooks_loaded")


func _on_pc_playbooks_loaded(playbooks:Array)-> void:
	pc_playbooks = {}
	if not pc_playbooks: pc_playbooks = {"roster": []}
	elif not "roster" in pc_playbooks: pc_playbooks["roster"] = []
	pc_playbooks["roster"] = playbooks

	for playbook in playbooks:
		if not playbook is PlayerPlaybook: continue
		if not playbook.is_connected("changed", self, "_on_playbook_updated"):
			playbook.connect("changed", self, "_on_playbook_updated", [playbook])


func _on_playbook_updated(playbook:Playbook)->void:
	GameSaver.save(playbook)


func _on_clock_updated(id:String, clock_data:={})->void:
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
	self.map = save.map
	emit_signal("map_loaded", map)


func _set_save_game(new_save: SaveGame)-> void:
	if new_save.needs_setup: new_save.setup_save()
	clocks = new_save.clocks
	map = new_save.map

	save_game = new_save


func _set_clocks_being_saved(value: bool)-> void:
	if not value: emit_signal("clocks_free")
	clocks_being_saved = value


#Save all current game data to disk. Package the data, push it to GameSaver
func save_all()-> void:
	var data: = []
	save_clocks()
	save_map()
	data = [save_game, crew_playbook, pc_playbooks]
	GameSaver.save_all(data)


func add_pc_to_roster(pc:PlayerPlaybook)-> void:
	pc_playbooks.roster.append(pc)
	GameSaver.save(pc)


func save_map()-> void:
	save_game.map = map


func add_map_note(pos:Vector2, data:Dictionary)-> void:
	if not "notes" in map:
		map["notes"] = {}

	map.notes[pos] = data
	save_map()


func save_clocks()->void:
	self.clocks_being_saved = true
	save_game.clocks = clocks
	self.clocks_being_saved = false


func get_clocks()-> Array:
	if clocks_being_saved:
		yield(self, "clocks_free")
	clocks = save_game.clocks
	return clocks


func _on_crew_loaded(crew: CrewPlaybook)-> void:
	if crew_playbook:
		if crew_playbook.is_connected("changed", self, "_on_playbook_updated"):
			crew_playbook.disconnect("changed", self, "_on_playbook_updated")
	if not crew.is_connected("changed", self, "_on_playbook_updated"):
		crew.connect("changed", self, "_on_playbook_updated",[crew])
	crew_playbook = crew
