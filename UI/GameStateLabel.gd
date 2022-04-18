extends Label


func _ready() -> void:
	self.text = GameData.game_state
	GameData.connect("game_state_changed", self, "_on_game_state_changed")


func _on_game_state_changed(new_game_state:String)-> void:\
	text = new_game_state
