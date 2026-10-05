extends Label

@export var battle: Battle

func _ready() -> void :
	battle.enemies_alive_updated.connect(_on_enemies_alive_update)
	text = "0"

func _on_enemies_alive_update(new_count: int) -> void :
	text = NumberFormatter.format(new_count)
