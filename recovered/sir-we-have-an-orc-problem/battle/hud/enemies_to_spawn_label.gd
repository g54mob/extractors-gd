extends Label

@export var battle: Battle

func _ready() -> void :
	set_process(false)
	await battle.ready
	set_process(true)

func _process(_delta: float) -> void :
	var enemies_to_spawn: int = battle.total_enemies_to_spawn - battle.total_enemies_spawned
	text = NumberFormatter.format(enemies_to_spawn)
