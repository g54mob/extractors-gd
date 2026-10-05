extends Label

@export var battle: Battle

func _ready() -> void :
	battle.enemies_killed.connect(_on_enemies_killed)
	text = "0"

func _on_enemies_killed(_count: int) -> void :
	text = NumberFormatter.format(battle.total_enemies_killed)
