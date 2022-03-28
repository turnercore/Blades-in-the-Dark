extends Popup

onready var pages: Array = $SetupPages.get_children()
var active_page = 0
var current_page: Node
var crew_playbook: CrewPlaybook

func _ready() -> void:

	for page in pages:
		page.visible = false

	current_page = pages.front()
	current_page.visible = true

func _on_next() -> void:
	current_page.visible = false
	active_page += 1
	current_page = pages[active_page]
	current_page.visible = true


func _on_FinishedButton_pressed() -> void:
	#Do the crew setup code

	Events.emit_signal("popup_finished", crew_playbook)
	queue_free()

