extends Label

func _ready() -> void:
	text = str(ProjectSettings.get_setting("application/config/version"))
