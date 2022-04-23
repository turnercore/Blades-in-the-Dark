class_name Cursor
extends Area2D

const POSITION_UPDATE_SMOOTHING: = 0.5
var OP_CODE:int = Globals.OP_CODES.PLAYER_UPDATE

onready var sprite: = $Sprite
onready var tween:Tween = $Tween
onready var online:bool = ServerConnection.is_connected_to_server

var default_texture: Texture = preload("res://Shared/Art/Icons/icon.png")
var default_scale: = Vector2(1, 1)

var current_note_target = null
var current_target = null
var current_target_type:String = "none"

var allowed_rpcs: = ["remote_update_position"]
var user_id:String = ServerConnection._match.self_user.user_id if ServerConnection._match else "local_player_cursor"
var is_remote: = false setget _set_is_remote

var has_pos_changed: = false

func _ready() -> void:
	Events.connect("popup", self, "_on_popup")
	Events.connect("popup_finished", self, "_on_popup_finished")
	ServerConnection.connect("server_connected", self, "_on_server_connected")
	ServerConnection.connect("match_joined", self, "_on_match_joined")
	ServerConnection.connect("data_recieved", self, "_on_data_recieved")
	ServerConnection.connect("presences_changed", self, "_on_presences_changed")
	if is_remote:
		set_process(false)


func _process(_delta: float) -> void:
	if global_position != get_global_mouse_position():
		update_position(get_global_mouse_position())



func _input(event: InputEvent) -> void:
	if event.is_action_pressed("left_click"):
		match current_target_type:
			"location":
				Events.emit_signal("map_note_clicked", current_note_target)
			_:
				pass


func remote_update_position(pos:Vector2)-> void:
	tween.interpolate_property(
		self,
		"global_position",
		null,
		pos,
		POSITION_UPDATE_SMOOTHING,
		Tween.TRANS_LINEAR,
		Tween.EASE_IN_OUT
	)
	tween.start()


func update_position(pos:Vector2)-> void:
	global_position = pos
	if online:
		has_pos_changed = true


func _on_cursor_area_entered(area: Area2D) -> void:
	if not visible: return

	if area.is_in_group("location"):
		default_texture = sprite.texture
		default_scale = sprite.scale

		sprite.texture = load("res://Shared/Art/Icons/info_icon.png")
		sprite.scale = Vector2(0.05, 0.05)
		current_note_target = area
		current_target_type = "location"


func _on_cursor_area_exited(_area: Area2D) -> void:
	sprite.texture = default_texture
	sprite.scale = default_scale
	current_target = null
	current_target_type = "none"


func _on_VisibilityNotifier2D_viewport_entered(_viewport: Viewport) -> void:
	self.visible = true
	self.monitorable = true
	self.monitoring = true


func _on_VisibilityNotifier2D_viewport_exited(_viewport: Viewport) -> void:
	self.visible = false
	self.monitorable = false
	self.monitoring = false


func _on_popup(_ignored, _overlay)-> void:
	set_process(false)
	monitorable = false
	monitoring = false

func _on_popup_finished()-> void:
	set_process(true)
	monitorable = true
	monitoring = true


func _on_server_connected()-> void:
	online = ServerConnection.is_connected_to_server


func _on_data_recieved(data)-> void:
	if not "user_id" in data or data.user_id != user_id:
		return
	if not "rpc" in data or not data.rpc in allowed_rpcs:
		return
	if not "op_code" in data or not data.op_code == OP_CODE:
		return
	data.pos = Globals.str_to_vec2(data.pos)
	call(data.rpc, data.pos)


func _on_presences_changed()-> void:
	var i_am_deleted: = false
	for presence in ServerConnection.presences:
		if user_id == presence:
			i_am_deleted = true

	if i_am_deleted:
		queue_free()

func _set_is_remote(value:bool)-> void:
	is_remote = value
	set_process(not value)


func _on_match_joined()-> void:
	user_id = ServerConnection._match.self_user.user_id if ServerConnection._match else "local_player_cursor"


func _on_ServerUpdateTimer_timeout() -> void:
	if online and has_pos_changed:
		var data: = {
			"pos": global_position,
			"user_id": user_id,
			"rpc": "remote_update_position"
		}
		var result:int = yield(ServerConnection.send_match_state_async(OP_CODE, data), "completed")
		if result != OK:
			print("ERROR SENDING MATCH DATA ON PLAYER POS")
	has_pos_changed = false
