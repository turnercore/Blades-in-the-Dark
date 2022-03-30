extends PanelContainer

const DISMISS_TIMING: = 2.0
const DISAPPEAR_TIMING: = 0.4

onready var tween: = $Tween
onready var dismiss_timer: = $DismissTimer
export (NodePath) onready var info_label = get_node(info_label) as Label



func _ready() -> void:
	Events.connect("info_broadcasted", self, "_on_info_broadcasted")


func _on_info_broadcasted(info: String)->void:
	if info == "":
		dismiss_timer.start(DISMISS_TIMING)
	else:
		info_label.text = info
		dismiss_timer.stop()
		tween.interpolate_property(
			self,
			"modulate",
			null,
			Color(1,1,1,1),
			DISAPPEAR_TIMING,
			Tween.TRANS_QUART,
			Tween.EASE_OUT
		)
		tween.start()


func _on_DismissTimer_timeout() -> void:
	tween.interpolate_property(
		self,
		"modulate",
		null,
		Color(1,1,1,0),
		DISAPPEAR_TIMING,
		Tween.TRANS_QUART,
		Tween.EASE_OUT
	)
	tween.start()
