extends PopupScreen

export (NodePath) onready var result_text_label = get_node(result_text_label) as Label
export (NodePath) onready var match_name_line_edit = get_node(match_name_line_edit) as LineEdit
export (NodePath) onready var match_password_line_edit = get_node(match_password_line_edit) as LineEdit


func _on_CreateMatchButton_pressed() -> void:
	result_text_label.text = "Creating Match..."

	var result: int

	result = yield(ServerConnection.create_match_async(), "completed")

	if result == OK:
		result_text_label.text = "Match Created"
		ServerConnection.is_host = true
	else:
		result_text_label.text = "Error code %s: %s" % [result, ServerConnection.error_message]

