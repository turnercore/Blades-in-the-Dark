class_name Claim
extends TextureButton

export (String) var claim_name: String = "claim"
export (NodePath) onready var claim_label = get_node(claim_label) as Label
export (NodePath) onready var faction_label = get_node(faction_label) as Label
export(bool) var starting_claim:bool = false
var tooltip:String

var _playbook:CrewPlaybook

var restricted_paths:bool = false

var is_claimed:bool = false setget _set_is_claimed
var is_available:bool = true
export (bool) var is_prison:bool = false
var faction: String
var effect: String
var notes: String

var connections: Array
var connectors:Dictionary
var connection_node_names:Array


func _ready() -> void:
	claim_label.text = claim_name


func setup(playbook: CrewPlaybook) -> void:
	_playbook = playbook

	if not name in playbook.claims:
		print("can't find cell " + name + " in playbook.claims")
		return

	var cell = playbook.claims[name] if not is_prison else playbook.prison_claims[name]
	self.claim_name = cell.claim
	self._set_connections(cell.connections)
	self.faction = cell.faction if cell.faction else ""
	self.effect = cell.effect if cell.effect else ""
	self.is_claimed = true if cell.is_claimed else false
	self.notes = cell.notes if cell.notes else ""


func _set_connections(connection_str: String)-> void:
	#Input should be a string of n, s, e, w (or some combonation of such)
	var connection_array: = connection_str.split(",", false, 4)
	connection_node_names.clear()
	connectors.clear()


	#This only works for regular claim grid, prison claim gride is smaller, refactor or add prison
	for c in connection_array:
		c = c.strip_edges()
		var conn_name1: = ""
		var conn_name2: = ""
		#In comments, pretend this cell is c5
		match c:
			"n":
				#Connectors would be named: c5_c0 or c0_c5, so add both to the conneciton_nodes
				var next_cell_number: int = int(float(name.replace("c", ""))) - 5
				conn_name1 = name + "_c" + str(next_cell_number)
				conn_name2 = "c" + str(next_cell_number) + "_" + name
			"s":
				#Connectors would be named: c5_c10 or c10_c5, so add both to the conneciton_nodes
				var next_cell_number: int = int(float(name.replace("c", ""))) + 5
				conn_name1 = name + "_c" + str(next_cell_number)
				conn_name2 = "c" + str(next_cell_number) + "_" + name
			"e":
				#Connectors would be named: c5_c6 or c6_c5, so add both to the conneciton_nodes
				var next_cell_number: int = int(float(name.replace("c", ""))) + 1
				conn_name1 = name + "_c" + str(next_cell_number)
				conn_name2 = "c" + str(next_cell_number) + "_" + name

			"w":
				#Connectors would be named: c5_c4 or c4_c5, so add both to the conneciton_nodes
				var next_cell_number: int = int(float(name.replace("c", ""))) - 1
				conn_name1 = name + "_c" + str(next_cell_number)
				conn_name2 = "c" + str(next_cell_number) + "_" + name

		connection_node_names.append(conn_name1)
		connection_node_names.append(conn_name2)

	for conn in get_parent().get_children():
		if conn.is_in_group("claims") or "invisble" in conn.name: continue
		elif conn is ClaimTreeConnector: connectors[conn.name] = conn


	for connector in connection_node_names:
		if connector in connectors.keys():
			if connectors[connector].has_method("activate"): connectors[connector].activate()


func _process(_delta: float) -> void:
	if not visible: return

	if starting_claim:
		is_available = true
		is_claimed = true
		disabled = false
		pressed = true
		faction_label.visible = false
		return

	if is_claimed:
		faction_label.visible = false
		is_available = true
	else:
		faction_label.visible = true

	if restricted_paths:
		if is_available:
			disabled = false
		else:
			disabled = true
	else:
		disabled = false

	faction_label.text = faction
	tooltip = effect
	claim_label.text = claim_name


func check_connections() -> void:
	var is_connected_to_something: = false
	for node in connections:
		if not node.active: continue

		if node.has_partial_connection:
			is_connected_to_something = true
			disabled = false
			is_available = true
			break

	if not is_connected_to_something:
		is_available = false


func _on_fully_disconnected()-> void:
	check_connections()


func _on_connector_partially_connected()-> void:
	check_connections()


func _on_Claim_toggled(button_pressed: bool) -> void:
	self.is_claimed = button_pressed


func _set_is_claimed(value:bool)->void:
	is_claimed = value
	if pressed != is_claimed:
		pressed = is_claimed
	if not _playbook:
		return
	if name in _playbook.claims:
		_playbook.claims[name].is_claimed = is_claimed
		GameSaver.save_crew(_playbook)


func _on_Claim_mouse_entered() -> void:
	Tooltip.display_tooltip(claim_name, tooltip)



func _on_Claim_mouse_exited() -> void:
	Tooltip.finish_tooltip(claim_name, tooltip)
