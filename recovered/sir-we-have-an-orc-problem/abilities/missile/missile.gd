class_name Missile
extends Sprite2D


var target_pos: Vector2
var time_to_target: float

const BASE_DAMAGE: float = 2.0
const BASE_RADIUS: float = 4.0
const BASE_COOLDOWN: float = 1.0
const BASE_SHRAPNEL_DAMAGE: float = 1.0
const BASE_SLOW_DURATION: float = 1.0
const BASE_SLOW_STRENGTH: int = 20
const BASE_SHRAPNEL_HEALTH: float = 1.0

var explosion_damage: float = BASE_DAMAGE
var explosion_radius: float = BASE_RADIUS
var shrapnel_count: int = 0
var shrapnel_health: float = BASE_SHRAPNEL_HEALTH
var shrapnel_damage: float = BASE_SHRAPNEL_DAMAGE
var shrapnel_slow_duration: float = BASE_SLOW_DURATION

static var missiles_spawned: int = 0
var line: Line2D


static func is_unlocked() -> bool:
	return true

static func get_damage() -> float:
	return (BASE_DAMAGE
		+ TechTree.get_upgrade(&"missile_damage").current_value
		+ TechTree.get_upgrade(&"missile_damage_2").current_value
		+ TechTree.get_upgrade(&"missile_damage_3").current_value
		+ TechTree.get_upgrade(&"missile_damage_4").current_value)

static func get_radius() -> float:
	return (BASE_RADIUS
		+ TechTree.get_upgrade(&"missile_radius").current_value
		+ TechTree.get_upgrade(&"missile_radius_2").current_value)

static func get_cooldown() -> float:
	return (BASE_COOLDOWN
		+ TechTree.get_upgrade(&"missile_cooldown").current_value
		+ TechTree.get_upgrade(&"missile_cooldown_2").current_value)

static func get_shrapnel_count() -> int:
	return int(TechTree.get_upgrade(&"missile_shrapnel_count").current_value
		+ TechTree.get_upgrade(&"missile_shrapnel_count_2").current_value)

static func get_shrapnel_damage() -> float:
	return (BASE_SHRAPNEL_DAMAGE
		+ TechTree.get_upgrade(&"missile_shrapnel_damage").current_value

	)

static func get_shrapnel_health() -> float:
	return (BASE_SHRAPNEL_HEALTH
		+ TechTree.get_upgrade(&"missile_shrapnel_penetration").current_value

	)

static func get_shrapnel_slow_duration() -> float:
	return (BASE_SLOW_DURATION
		+ TechTree.get_upgrade(&"missile_shrapnel_slow_duration").current_value

	)

static func get_shrapnel_slow_strength() -> int:
	return int(BASE_SLOW_STRENGTH
		+ TechTree.get_upgrade(&"missile_shrapnel_slow_strength").current_value

	)



func bezier_pos_global(t: float, node: Node2D, start: Vector2, end: Vector2, p: Vector2) -> void :
	var q0: Vector2 = start.lerp(p, t)
	var q1: Vector2 = p.lerp(end, t)
	node.global_position = q0.lerp(q1, t)
	line.add_point(line.to_local( %LineMarker.global_position))
	if line.get_point_count() >= 16:
		line.remove_point(0)

func linear_rotation(t: float, node: Node2D, start_direction: Vector2, end_direction: Vector2) -> void :
	var dir: Vector2 = start_direction.lerp(end_direction, t)
	node.rotation = atan2(dir.y, dir.x)

func remove_point(t: float, line_node: Line2D) -> void :
	var points_remaining: = int(t)
	while line_node.get_point_count() > points_remaining:
		line_node.remove_point(0)

var battle: Battle
var target_sprite: Node2D

func _ready() -> void :
	explosion_damage = get_damage()
	explosion_radius = get_radius()
	shrapnel_count = get_shrapnel_count()
	shrapnel_health = get_shrapnel_health()
	shrapnel_slow_duration = get_shrapnel_slow_duration()

	line = load("res://abilities/missile/missile_line.tscn").instantiate()
	get_parent().add_child(line)
	missiles_spawned += 1
	var to_target: = target_pos - global_position
	var ortho: = to_target.normalized().orthogonal()
	var left_right: = 1.0
	if missiles_spawned % 2 == 0:
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

	AudioManager.play_ui_sound(Constants.missile_swoosh, 0.0, randf_range(0.9, 1.1))

	var tween: = create_tween()
	tween.set_parallel(true)
	tween.tween_method(bezier_pos_global.bind(self, global_position, target_pos, half_pos), 0.0, 1.0, time_to_target).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE * 0.25, time_to_target).set_ease(Tween.EASE_IN)
	tween.tween_method(linear_rotation.bind(self, dir_to_half_pos, dir_half_to_end), 0.0, 1.0, time_to_target).set_ease(Tween.EASE_IN)
	tween.chain()
	tween.tween_callback(explode)

	target_sprite = Constants.missile_target_scene.instantiate()
	target_sprite.global_position = target_pos
	get_parent().add_child(target_sprite)


func explode() -> void :
	var push_force: = 2.0

	var expl: Rigidbody = Rigidbody.new(target_pos, Vector2.ZERO, explosion_radius, 1.0 / push_force, 0.0)
	expl.layer = Rigidbody.Layers.EXPLOSIONS
	expl.sensor_mask = Rigidbody.Layers.ENEMIES
	expl.lifetime = 0.0
	expl.ch_damage_other = explosion_damage
	expl.ch_damage_falloff = 1.0
	expl.ch_flags = 0
	expl.ch_damage_report_id = Constants.DAMAGE_REPORT_ID_MISSILE
	GPUSim.add_rigidbodies([expl])

	if shrapnel_count > 0:
		var shrapnels: Array[Rigidbody] = []
		shrapnels.resize(shrapnel_count)
		for i: int in shrapnel_count:
			var angle: = PI * 2.0 * randf()
			var vel: = Vector2.from_angle(angle) * 300.0
			var shrapnel: Rigidbody = Rigidbody.new(target_pos, vel, 0.5, 1.0, shrapnel_health)
			shrapnel.layer = Rigidbody.Layers.PROJECTILES
			shrapnel.sensor_mask = Rigidbody.Layers.ENEMIES | Rigidbody.Layers.TERRAIN
			shrapnel.collision_mask = 0
			shrapnel.lifetime = 0.5
			shrapnel.ch_damage_self = 1.0
			shrapnel.ch_damage_other = shrapnel_damage
			shrapnel.ch_flags = Rigidbody.ContactHandlerFlags.KILL_IF_OTHER_TERRAIN
			shrapnel.ch_damage_report_id = Constants.DAMAGE_REPORT_ID_MISSILE
			shrapnel.ch_slow_timer = shrapnel_slow_duration
			shrapnels[i] = shrapnel
		GPUSim.add_rigidbodies(shrapnels)

	AudioManager.play_sound_at(Constants.explosion_sound, target_pos, 0.0, randf_range(0.9, 1.1) * clampf(10.0 / log(explosion_radius), 0.5, 2.0))
	queue_free()
	var line_fade_tween: = line.create_tween()


	line_fade_tween.tween_method(remove_point.bind(line), line.get_point_count(), 0.0, 0.5)
	line_fade_tween.tween_callback(line.queue_free)

	target_sprite.queue_free()
