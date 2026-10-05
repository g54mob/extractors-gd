class_name TowerPlacement
extends Node2D

var current_tower: BaseTower = null

func _spawn_tower_at_pos(tower_kind: BaseTower.TowerKind, pos: Vector2) -> BaseTower:
	var tower: BaseTower = load(BaseTower.TOWER_SCENES[tower_kind]).instantiate()
	tower.global_position = pos
	add_child(tower)
	return tower

func spawn_tower(tower_kind: BaseTower.TowerKind) -> void :
	if current_tower:
		if current_tower.was_constructed:
			return
		@warning_ignore("static_called_on_instance")
		if current_tower.get_kind() == tower_kind:
			current_tower.queue_free()
			return
		current_tower.queue_free()
	(get_tree().current_scene as Battle).unselect_all_towers()
	current_tower = _spawn_tower_at_pos(tower_kind, get_global_mouse_position())
	current_tower.edit_mode = BaseTower.EditMode.MOVABLE
	current_tower.input_style = BaseTower.InputStyle.PRESS
	current_tower.editing_finished.connect(
		func() -> void :
			current_tower = null
			if BaseTower.get_towers_built(tower_kind) < BaseTower.get_tower_limit(tower_kind):
				spawn_tower(tower_kind), 
		CONNECT_ONE_SHOT)
	current_tower.aborted.connect( func() -> void :
		current_tower = null, 
		CONNECT_ONE_SHOT)
