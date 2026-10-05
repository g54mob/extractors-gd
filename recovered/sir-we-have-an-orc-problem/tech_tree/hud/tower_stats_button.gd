extends Button

@export var id: String

var wobble_tween: Tween = null

func _ready() -> void :
	TechTree.upgrades_changed.connect(update_visibility)
	update_visibility()

	var should_animate: bool = !GameManager.has_seen_tower_stats.get(id, false)
	if should_animate:
		animate()

func _on_button_toggled(toggled_on: bool, idx: int) -> void :
	%StatsVBox.get_child(idx).visible = toggled_on
	var already_saved: bool = GameManager.has_seen_tower_stats.get(id, false)
	if toggled_on and !already_saved:
		GameManager.has_seen_tower_stats[id] = true
		if wobble_tween:
			await wobble_tween.loop_finished
			wobble_tween.kill()
			wobble_tween = null
		SaveSystem.save_save_data()

func update_visibility() -> void :
	if id == "missile":
		visible = true
		return

	visible = TechTree.get_upgrade(id + "_unlock").level > 0

func animate() -> void :
	wobble_tween = create_tween().bind_node(self)
	wobble_tween.set_loops()
	wobble_tween.tween_property(self, "pivot_offset", self.size / 2.0, 0)
	wobble_tween.tween_property(self, "rotation_degrees", -8, 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	wobble_tween.parallel().tween_property(self, "scale", Vector2(1.2, 1.2), 0.08)
	wobble_tween.tween_property(self, "rotation_degrees", 8, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	wobble_tween.tween_property(self, "rotation_degrees", 0, 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	wobble_tween.tween_property(self, "rotation_degrees", -8, 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	wobble_tween.tween_property(self, "rotation_degrees", 8, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	wobble_tween.tween_property(self, "rotation_degrees", 0, 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	wobble_tween.parallel().tween_property(self, "scale", Vector2.ONE, 0.16)
	wobble_tween.tween_property(self, "pivot_offset", Vector2.ZERO, 0)
	wobble_tween.tween_interval(1.5)
