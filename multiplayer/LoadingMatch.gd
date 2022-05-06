extends PopupScreen

var QUIPS: =[
	"Stabbing the darkness.",
	"Thanking John Harper.",
	"Eating Fruit Loops.",
	"I could tell you but I'd have to charge...",
	"Databasing static typed variables.",
	"Getting server messages.",
	"Retrieving current game state from host.",
	"Resting.",
	"Fiction-first Gaming.",
	"Wondering what prune juice really is.",
	"Fabricating birds.",
	"Whispering to the dead.",
	"Interrogating Micky",
	"Finding get-away driver.",
	"Cracking safe.",
	"Throwing ecto-plasmic energy.",
	"Finding a lair.",
	"Acquring assets.",
	"Lighting rivels",
	"Showing force",
	"Smuggling contraband.",
	"Filling coffers.",
	"Preparing...",
	"Installing Flashbacks.",
	"Setting up claim grid.",
	"Hiding Lurks.",
	"Taming ghosts.",
	"Backstabbing vampries.",
	"Entangling factions.",
	"Supprising Bobby"
]
onready var loading_label: = $PanelContainer/VBoxContainer/LoadingLabel
onready var tween: = $Tween
onready var loading_quip: = $PanelContainer/VBoxContainer/LoadingNotification
onready var quip_timer: = $QuipTimer
var online: bool = false


func _ready() -> void:
	GameData.connect("game_state_loaded", self, "_on_game_state_loaded")
	if online:
		print("Requesting current match state from host")
		GameData.request_game_state()

func _on_game_state_loaded()-> void:
	print("Game State LOADED!")
	Events.emit_signal("all_popups_finished")
	get_tree().change_scene_to(Globals.GAME_SCENE)


func _process(delta: float) -> void:
	loading_label.percent_visible = clamp(loading_label.percent_visible + delta/1.10, 0, 1)
	if loading_label.percent_visible == 1:
		loading_label.percent_visible = 0


func _on_QuipTimer_timeout() -> void:
	tween.interpolate_property(
		loading_quip,
		"percent_visible",
		1,
		0,
		0.06,
		Tween.TRANS_LINEAR,
		Tween.EASE_IN_OUT
	)
	tween.start()
	yield(tween, "tween_all_completed")
	var new_quip: = ""
	if QUIPS.size() > 0:
		var index:int = randi()%QUIPS.size()
		new_quip = QUIPS[index]
		QUIPS.remove(index)
	else:
		new_quip = "This is taking quite some time............ Shit."
		quip_timer.paused = true
	tween.interpolate_property(
		loading_quip,
		"percent_visible",
		0,
		1,
		0.17,
		Tween.TRANS_LINEAR,
		Tween.EASE_IN_OUT
	)
	tween.start()
	loading_quip.text = new_quip

