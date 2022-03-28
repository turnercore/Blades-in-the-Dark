extends LineEdit

export (Array, String) var snarky_quips: Array = [
	"What do you have to say for yourself?",
	"Say something clever...",
	"Don't let your memes be dreams",
	"Edit twice, send once",
	"How many of these are there?",
	"If you don't have anything nice to say, perhaps don't say anything at all",
	"You must gather your thoughts before venturing forth"
]

func _ready() -> void:
	randomize()
	placeholder_text = snarky_quips[randi() % snarky_quips.size()]




func _on_SendMessageButton_pressed() -> void:
	placeholder_text = snarky_quips[randi() % snarky_quips.size()]
