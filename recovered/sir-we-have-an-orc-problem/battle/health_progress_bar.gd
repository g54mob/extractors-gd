extends ProgressBar

@export var delayed_progress_bar: ProgressBar
@export var health_label: Label

func _ready() -> void :
	var battle: Battle = get_tree().get_first_node_in_group("battle")
	battle.health_changed.connect(_on_health_changed)
	await battle.ready
	value = battle.health
	max_value = battle.health
	delayed_progress_bar.max_value = max_value
	health_label.text = "%d / %d" % [ceili(battle.health), ceili(max_value)]

const CATCH_UP_SPEED: float = 3.0
func _process(delta: float) -> void :
	delayed_progress_bar.value -= (delayed_progress_bar.value - value) * delta * CATCH_UP_SPEED

func _on_health_changed(new_amount: float) -> void :
	value = new_amount
	health_label.text = "%d / %d" % [ceili(value), ceili(max_value)]
