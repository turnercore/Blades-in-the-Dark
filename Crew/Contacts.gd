extends ScrollContainer


var playbook:Playbook setget _set_playbook



func _set_playbook(new_playbook:Playbook)-> void:
	playbook = new_playbook
	Globals.propagate_set_playbook_recursive(self, new_playbook, self)
