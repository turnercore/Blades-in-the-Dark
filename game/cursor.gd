class_name Cursor
extends Area2D

const POSITION_UPDATE_SMOOTHING: = 0.1
const ALLOWED_RPCS: = [
	"remote_update_position",
	"remote_change_sprite_to"
]
var OP_CODE:int = Globals.OP_CODES.PLAYER_UPDATE

onready var current_sprite: = $Player
onready var tween:Tween = $Tween
onready var online:bool = ServerConnection.is_connected_to_server

var default_texture: Texture = preload("res://Shared/Art/Icons/icon.png")
var default_scale: = Vector2(1, 1)

var current_note_target = null
var current_target = null
var current_target_type:String = "none"

var user_id:String = ServerConnection._match.self_user.user_id if ServerConnection._match else "local_player_cursor"
var is_remote: = false setget _set_is_remote

var has_pos_changed: = false

func _ready() -> void:
	if not is_remote:
		Events.connect("popup", self, "_on_popup")
		Events.connect("popup_finished", self, "_on_popup_finished")
	ServerConnection.connect("server_connected", self, "_on_server_connected")
	ServerConnection.connect("match_joined", self, "_on_match_joined")
	ServerConnection.connect("data_recieved", self, "_on_data_recieved")
	ServerConnection.connect("presences_changed", self, "_on_presences_changed")
	if is_remote:
		set_process(false)


func _process(_delta: float) -> void:
	if global_position != get_global_mouse_position() and not is_remote:
		update_position(get_global_mouse_position())
		if online:
			yield(ServerConnection.send_rpc_async("remote_update_position", OP_CODE, get_global_mouse_position()), "completed")



func _input(event: InputEvent) -> void:
	if event.is_action_pressed("left_click"):
		match current_target_type:
			"location":
				Events.emit_signal("map_note_clicked", current_note_target)
			_:
				pass


func change_sprite_to(sprite: String)-> void:
	_change_sprite(sprite)
	if online:
		var payload: = {
			"sprite": sprite,
			"user_id": user_id
		}
		var result:int = yield(ServerConnection.send_rpc_async("remote_change_sprite_to", OP_CODE, sprite), "completed")
		if result != OK:
			print("ERROR SENDING UPDATE SPRITE RPC")


func remote_change_sprite_to(sprite:String)-> void:
	print("Changing sprite remotely")
	if sprite == "":
		print("error with sprite string")
	_change_sprite(sprite)


func _change_sprite(sprite:String)-> void:
	sprite = sprite.to_lower().strip_edges()
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
			current_sprite.visible = true


func remote_update_position(pos)-> void:
	if pos is String:
		var vector_pos:Vector2 = Globals.str_to_vec2(pos)

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
#	if online:
#		has_pos_changed = true


func _on_cursor_area_entered(area: Area2D) -> void:
	if not visible: return

	if area.is_in_group("location"):
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


func _on_data_recieved(payload:Dictionary)-> void:
	if payload.rpc != "remote_update_position":
		print(payload)
	if not "op_code" in payload or not payload.op_code == OP_CODE:
		return
	if not "user_id" in payload.data or payload.user_id != user_id:
		return
	if not "rpc" in payload or not payload.rpc in ALLOWED_RPCS:
		if "rpc" in payload:
			print("Trying to call RPC " + payload.rpc + " which is not allowed")
		return
	if not "data" in payload:
		return

	call(payload.rpc, payload.data)


func _on_presences_changed()-> void:
	var i_am_deleted: = false
	for presence in ServerConnection.presences:
		if user_id == presence:
			i_am_deleted = true

	if i_am_deleted:
		queue_free()


func _set_is_remote(value:bool)-> void:
	is_remote = value
	if value: set_process(false)


func _on_match_joined()-> void:
	user_id = ServerConnection._match.self_user.user_id if ServerConnection._match else "local_player_cursor"


#func _on_ServerUpdateTimer_timeout() -> void:
#	if online and has_pos_changed:
#		var result:int = yield(ServerConnection.send_rpc_async("remote_update_position", OP_CODE, global_position), "completed")
#		if result != OK:
#			print("ERROR SENDING MATCH DATA ON PLAYER POS")
#	has_pos_changed = false
