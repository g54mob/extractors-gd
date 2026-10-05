extends Button

@export var unlock_upgrade: StringName = ""

func _ready() -> void :
	visible = unlock_upgrade.is_empty() or TechTree.get_upgrade(unlock_upgrade).level > 0
