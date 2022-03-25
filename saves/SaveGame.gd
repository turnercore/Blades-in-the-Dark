class_name SaveGame
extends Resource

export (String) var version: String = ''
export (Dictionary) var data: Dictionary = {}
export (Dictionary) var playbooks: = {}
export (Dictionary) var map: = {}
var needs_setup:bool = true

func setup()->void:
	needs_setup = false
