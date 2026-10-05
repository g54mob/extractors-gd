extends Node

var cheats_enabled: bool

var can_refund_upgrades: bool = false:
	get:
		return cheats_enabled and can_refund_upgrades

var skip_end_of_battle: bool = false:
	get:
		return cheats_enabled and skip_end_of_battle

func _ready() -> void :
	cheats_enabled = OS.has_feature("cheats")
