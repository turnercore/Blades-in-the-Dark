class_name Cursor
extends Area2D

const POSITION_UPDATE_INTERVAL: = 0.1

onready var current_sprite: = $Player
onready var tween:Tween = $Tween
onready var online:bool = ServerConnection.is_connected_to_server

var default_texture: Texture = preload("res://Shared/Art/Icons/icon.png")
var default_scale: = Vector2(1, 1)

var current_note_target = null
var current_target = null
var current_target_type:String = "none"

var _user_id:String = ServerConnection._match.self_user.user_id if ServerConnection._match else "local_player_cursor"
var is_remote: = false setget _set_is_remote

var has_pos_changed: = false
var new_pos: Vector2

func _ready() -> void:
	if not is_remote:
		Events.connect("popup", self, "_on_popup")
		Events.connect("popup_finished", self, "_on_popup_finished")
		var PositionUpdateTimer:= Timer.new()
		PositionUpdateTimer.connect("timeout", self, "_on_position_update_timeout")
		PositionUpdateTimer.wait_time = POSITION_UPDATE_INTERVAL
		PositionUpdateTimer.autostart = true
		add_child(PositionUpdateTimer)
		GameData.local_player.cursor = self

	ServerConnection.connect("server_connected", self, "_on_server_connected")
	ServerConnection.connect("match_joined", self, "_on_match_joined")
	ServerConnection.connect("presences_changed", self, "_on_presences_changed")
	NetworkTraffic.connect("player_movement_recieved", self, "_on_player_movement_recieved")
	NetworkTraffic.connect("player_sprite_changed", self, "_on_player_sprite_changed")


func setup_puppet(user_id:String)-> void:
	_user_id = user_id
	self.is_remote = true
	set_process(false)
	monitorable = false
	monitoring = false
	set_physics_process(false)
	set_process_input(false)
	set_process_unhandled_input(false)
	set_process_unhandled_key_input(false)
	set_collision_layer_bit(0, false)
	set_collision_mask_bit(0, false)
	input_pickable = false


func _process(_delta: float) -> void:
	if global_position != get_global_mouse_position() and not is_remote:
		update_position(get_global_mouse_position())
		if online:
			has_pos_changed = true
			new_pos = get_global_mouse_position()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("left_click"):
		match current_target_type:
			"location":
				Events.emit_signal("map_note_clicked", current_note_target)
				print("clicked location")
			_:
				pass


func change_sprite_to(sprite: String)-> void:
	if is_remote: return

	sprite = sprite.to_lower().strip_edges()
	_change_sprite(sprite)
	if online:
		var payload: = {
			"sprite": sprite,
			"user_id": _user_id
		}
		var result:int = yield(NetworkTraffic.send_data_async(NetworkTraffic.OP_CODES.PLAYER_SPRITE, payload), "completed")
		if result != OK:
			print("ERROR SENDING UPDATE SPRITE RPC")


func remote_change_sprite_to(sprite:String)-> void:
	sprite = sprite.to_lower().strip_edges()
	print("Changing sprite remotely")
	if sprite == "":
		print("error with sprite string")
	_change_sprite(sprite)


func _change_sprite(sprite:String)-> void:
	match sprite:
		"info":
			current_sprite.visible = false
			current_sprite = $Info
			current_sprite.visible = true
		"dice":
			current_sprite.visible = false
			current_sprite = $Dice
			current_sprite.visible = true
		"player":
			current_sprite.visible = false
			current_sprite = $Player
			current_sprite.visible = false


func remote_update_position(pos:Vector2)-> void:
#	global_position = pos
	tween.interpolate_property(
		self,
		"global_position",
		null,
		pos,
		POSITION_UPDATE_INTERVAL,
		Tween.TRANS_LINEAR,
		Tween.EASE_IN_OUT
	)
	tween.start()


func update_position(pos:Vector2)-> void:
	if is_remote: return
	global_position = pos
#	if online:
#		has_pos_changed = true


func _on_cursor_area_entered(area: Area2D) -> void:
	if not visible: return
	if area.is_in_group("location_note"):
		current_note_target = area
		current_target_type = "location"
		change_sprite_to("info")


func _on_cursor_area_exited(_area: Area2D) -> void:
	current_target = null
	current_target_type = "none"
	change_sprite_to("player")


func _on_VisibilityNotifier2D_viewport_entered(_viewport: Viewport) -> void:
	self.visible = true
	self.monitorable = true
	self.monitoring = true


func _on_VisibilityNotifier2D_viewport_exited(_viewport: Viewport) -> void:
	self.visible = false
	self.monitorable = false
	self.monitoring = false


func _on_popup(popup, _overlay)-> void:
	if popup is String:
		change_sprite_to(popup)
	elif "id" in popup:
		change_sprite_to(popup)
	set_process(false)
	monitorable = false
	monitoring = false


func _on_popup_finished()-> void:
	set_process(true)
	monitorable = true
	monitoring = true
	change_sprite_to("player")


func _on_server_connected()-> void:
	online = ServerConnection.is_connected_to_server


func _on_player_movement_recieved(user_id:String, pos:Vector2)-> void:
	if user_id == _user_id:
		remote_update_position(pos)


func _on_player_sprite_changed(user_id:String, sprite:String)-> void:
	if user_id == _user_id:
		remote_change_sprite_to(sprite)


func _on_presences_changed(presences)-> void:
	var i_am_deleted: = false
	for presence in presences:
		if _user_id == presence:
			i_am_deleted = true

	if i_am_deleted:
		queue_free()


func _set_is_remote(value:bool)-> void:
	is_remote = value
	if value: set_process(false)


func _on_match_joined()-> void:
	_user_id = ServerConnection._match.self_user.user_id if ServerConnection._match else "local_player_cursor"


func _on_position_update_timeout()-> void:
	if has_pos_changed and not is_remote:
		var payload: = {
				"pos": new_pos,
				"user_id": _user_id
			}
		var result = yield(NetworkTraffic.send_data_async(NetworkTraffic.OP_CODES.PLAYER_MOVEMENT, payload), "completed")
		if result != OK:
			print("ERROR UPDATING PLAYER POS REMOTELY")
		has_pos_changed = false
