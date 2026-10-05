extends PanelContainer

var tween: Tween
var battle: Battle

func _ready() -> void :
	battle = get_tree().get_first_node_in_group("battle")
	battle.paused_changed.connect(_on_paused_changed)
	tween = create_tween()
	tween.set_loops(0)
	tween.tween_property(self, "modulate:a", 0.1, 1.0).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "modulate:a", 1.0, 1.0).set_ease(Tween.EASE_IN_OUT)
	tween.pause()
	_on_paused_changed(battle.is_paused)

func _on_paused_changed(paused: bool) -> void :
	visible = paused
	if paused and battle.phase == Battle.Phase.BATTLE:
		tween.play()
	else:
		tween.pause()
