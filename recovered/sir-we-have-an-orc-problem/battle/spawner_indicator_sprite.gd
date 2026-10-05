extends Sprite2D

var battle: Battle
func _ready() -> void :
	battle = get_tree().get_first_node_in_group("battle")
	battle.paused_changed.connect(_on_battle_paused_changed)
	var tween: = create_tween()
	tween.set_loops(0)
	tween.tween_property(self, "scale", Vector2.ONE * 1.2, 1.0).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector2.ONE, 1.0).set_ease(Tween.EASE_OUT)

func _on_battle_paused_changed(paused: bool) -> void :
	visible = paused and battle.phase < Battle.Phase.END
