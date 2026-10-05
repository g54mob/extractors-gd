class_name Nuke extends Node2D

const BASE_DAMAGE: float = 120.0
const BASE_RADIUS: float = 150.0

static func is_unlocked() -> bool:
	return TechTree.get_upgrade(&"nuke_unlock").level > 0

static func get_damage() -> float:
	return (BASE_DAMAGE
		+ TechTree.get_upgrade(&"nuke_damage").current_value


		)

static func get_radius() -> float:
	return (BASE_RADIUS
		+ TechTree.get_upgrade(&"nuke_radius").current_value

		)

static func get_uses() -> int:
	return roundi(1
		+ TechTree.get_upgrade(&"nuke_count").current_value
	)

var target_pos: Vector2
var time_to_target: float
var explosion_damage: float = 1.0
var explosion_radius: float = 4.0

var line: Line2D
var battle: Battle
var target_sprite: Node2D

func _ready() -> void :
	explosion_damage = get_damage()
	explosion_radius = get_radius()
	line = load("res://abilities/missile/missile_line.tscn").instantiate()
	get_parent().add_child(line)
	Missile.missiles_spawned += 1
	var to_target: = target_pos - global_position
	var ortho: = to_target.normalized().orthogonal()
	var left_right: = 1.0
	if Missile.missiles_spawned % 2 == 0:
		left_right = -1.0
	ortho *= left_right
	global_position.x += left_right * -40.0
	line.add_point(line.to_local( %LineMarker.global_position))
	var half_pos: = global_position + to_target * 0.5 + ortho * randf_range(50.0, 100.0)
	rotation = to_target.normalized().angle()
	scale = Vector2.ONE * 4.0

	var dir_to_half_pos: = (half_pos - global_position).normalized()
	rotation = atan2(dir_to_half_pos.y, dir_to_half_pos.x)
	var dir_half_to_end: = (target_pos - half_pos).normalized()

	AudioManager.play_ui_sound(Constants.bells_of_doom_sound, 0.0, randf_range(0.9, 1.1))

	var tween: = create_tween()
	tween.set_parallel(true)
	tween.tween_method(bezier_pos_global.bind(self, global_position, target_pos, half_pos), 0.0, 1.0, time_to_target).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE * 0.25, time_to_target).set_ease(Tween.EASE_IN)
	tween.tween_method(linear_rotation.bind(self, dir_to_half_pos, dir_half_to_end), 0.0, 1.0, time_to_target).set_ease(Tween.EASE_IN)
	tween.chain()
	tween.tween_callback(explode)

	target_sprite = Constants.nuke_target_scene.instantiate()
	target_sprite.global_position = target_pos
	(target_sprite.get_child(0) as AnimationPlayer).play(&"default")
	get_parent().add_child(target_sprite)

func bezier_pos_global(t: float, node: Node2D, start: Vector2, end: Vector2, p: Vector2) -> void :
	var q0: Vector2 = start.lerp(p, t)
	var q1: Vector2 = p.lerp(end, t)
	node.global_position = q0.lerp(q1, t)
	line.add_point(line.to_local( %LineMarker.global_position))
	if line.get_point_count() >= 4:
		line.remove_point(0)

func linear_rotation(t: float, node: Node2D, start_direction: Vector2, end_direction: Vector2) -> void :
	var dir: Vector2 = start_direction.lerp(end_direction, t)
	node.rotation = atan2(dir.y, dir.x)

func remove_point(t: float, line_node: Line2D) -> void :
	var points_remaining: = int(t)
	while line_node.get_point_count() > points_remaining:
		line_node.remove_point(0)

func explode() -> void :
	var push_force: = 500.0

	var expl: Rigidbody = Rigidbody.new(target_pos, Vector2.ZERO, explosion_radius, 1.0 / push_force, 0.0)
	expl.layer = Rigidbody.Layers.EXPLOSIONS
	expl.sensor_mask = Rigidbody.Layers.ENEMIES
	expl.lifetime = 0.0
	expl.ch_damage_other = explosion_damage
	expl.ch_damage_falloff = 1.0
	expl.ch_flags = 0
	expl.ch_damage_report_id = Constants.DAMAGE_REPORT_ID_NUKE
	GPUSim.add_rigidbodies([expl])


	AudioManager.play_ui_sound(Constants.nuke_explosion_sound, 0.0, randf_range(0.9, 1.1))

	queue_free()
	var line_fade_tween: = line.create_tween()
	line_fade_tween.tween_method(remove_point.bind(line), line.get_point_count(), 0.0, 0.5)
	line_fade_tween.tween_callback(line.queue_free)

	target_sprite.queue_free()
