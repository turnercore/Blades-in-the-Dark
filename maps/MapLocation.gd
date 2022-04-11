class_name MapNote
extends Area2D

export(String) var location_name
export (String, MULTILINE) var info_text
export(PackedScene) var edit_note_popup
onready var anim:= $AnimationPlayer


func _ready() -> void:
	$MapNoteTexture/Label.text = location_name
	$MapNoteTexture/Label2.text = info_text
	Events.connect("map_note_clicked", self, "_on_clicked")
	shrink()


func _on_clicked(note)->void:
	if note == self:
		Events.popup(create_popup())


func _on_mouse_entered(_area = null) -> void:
	if not info_text:
		return
	Events.emit_signal("info_broadcasted", info_text)
	enlarge()


func _on_mouse_exited(_area = null) -> void:
	Events.emit_signal("info_broadcasted", "")
	shrink()

func enlarge()-> void:
	anim.play("enlarge")


func shrink()-> void:
	anim.play("shrink")


func create_popup()-> EditNotePopup:
	var popup:EditNotePopup = edit_note_popup.instance()
	popup.location_name = location_name
	popup.info_text = info_text

	return popup
#
#func _on_MapNote_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
#	if event.is_action_pressed("left_click"):
#
#		print("WHHAH")
