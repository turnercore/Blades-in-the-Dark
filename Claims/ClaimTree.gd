extends GridContainer

export (bool) var restricted_paths: = false

onready var children: = get_children()


func _ready() -> void:
	connect_claims_to_connectors()
	connect_connectors_to_claims()
	set_starting_states()



func set_starting_states()->void:
	for claim in children:
		if not claim.is_in_group("claims"): continue

		if claim.is_claimed:
			claim.is_available = true
		if restricted_paths:
			claim.restricted_paths = true



func connect_connectors_to_claims()->void:
	for connector in children:
		if connector.is_in_group("claims") or "invisble" in connector.name: continue

		var cells:Array = connector.name.split("_", false, 2)
		var cells_connected: = 0

		for claim in children:
			if not claim.is_in_group("claims"): continue

			if cells_connected >= 2:
				break
			elif claim.name in cells:
				connector.connections.append(claim)
				cells_connected += 1

		for claim in connector.connections:
			if claim.has_signal("toggled") and claim.is_in_group("claims"):
				claim.connect("toggled", connector, "_on_neighbor_toggled")



func connect_claims_to_connectors()->void:
	for claim in children:
		if not claim.is_in_group("claims"): continue

		for connector in get_children():
			if connector.is_in_group("claims"): continue
			if connector.has_signal("partially_connected") and connector.has_signal("fully_disconnected"):
				var split_name: Array = connector.name.split("_", false, 2)
				for part in split_name:
					if claim.name == part:
						if claim.connections.has(connector): continue
						else:
							claim.connections.append(connector)
							connector.connect("partially_connected", claim, "_on_connector_partially_connected")
							connector.connect("fully_disconnected", claim, "_on_fully_disconnected")


func _on_RestrictedPathsButton_toggled(button_pressed: bool) -> void:
	restricted_paths = button_pressed
	for claim in children:
		if not claim.is_in_group("claims"): continue
		claim.restricted_paths = restricted_paths
		if not restricted_paths:
			claim.disabled = false

