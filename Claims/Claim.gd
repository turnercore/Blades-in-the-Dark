extends TextureButton

export (String) var claim_name: String = "claim"
export (NodePath) onready var claim_label = get_node(claim_label) as Label
export (NodePath) onready var faction_label = get_node(faction_label) as Label
export(bool) var starting_claim:bool = false

var is_controlled_by_faction:bool = true

var restricted_paths:bool = false
var connectors: Array
var is_claimed:bool = false
var is_available:bool = false



func _ready() -> void:
	claim_label.text = claim_name



func _process(_delta: float) -> void:
	if starting_claim:
		is_available = true
		is_claimed = true
		disabled = false
		pressed = true
		faction_label.visible = false
		claim_label.text = "lair"
		claim_name = "lair"
		return

	if is_claimed:
		faction_label.visible = false
	else:
		faction_label.visible = true

	if restricted_paths:
		if is_available:
			disabled = false
		else:
			disabled = true
	else:
		disabled = false


func check_connections() -> void:
	var is_connected_to_something: = false
	for node in connectors:
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
	is_claimed = button_pressed
