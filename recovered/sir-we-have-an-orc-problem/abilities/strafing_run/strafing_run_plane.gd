class_name StrafingRunPlane extends Node2D

signal shooting_done
signal finished

var can_start: bool:
	get: return !visible

var start_pos: Vector2
var dir: Vector2
var length: float
var width: float
var battle: Battle
var end_pos: Vector2
var delay: float = 2.0
var shooting_time: float = 0.6
var bullet_delay: float = 0.2
var fire_rate: float
var bullet_count: int
var push_force: float = 200.0

var to_target: = Vector2.RIGHT
var audio_player: AudioStreamPlayer2D = null
var targets: PackedVector2Array = []
var explosion_timers: PackedFloat32Array = []

var total_time: float
var delta_overflow: float
var bullets_spawned: int
var explosions_spawned: int

func initialize(start_pos_in: Vector2, dir_in: Vector2, length_in: float, width_in: float, battle_in: Battle) -> void :
	start_pos = start_pos_in
	dir = dir_in
	length = length_in
	width = width_in
	battle = battle_in


func _ready() -> void :
	set_physics_process(false)
	bullet_count = StrafingRun.get_bullet_count()


func start() -> void :
	total_time = 0.0
	delta_overflow = 0.0
	bullets_spawned = 0
	explosions_spawned = 0
	set_physics_process(true)
	audio_player = null
	end_pos = start_pos + dir * length
	visible = true
	rotation = dir.angle()
	global_position = start_pos - dir * 1000.0
	var shadow_offset: Vector2 = Vector2(-100.0, 60.0)
	%MuzzleFire.visible = false

	var duration: = delay * 3.0
	var plane_tween: = create_tween()
	plane_tween.set_parallel()
	plane_tween.tween_property(self, "global_position", end_pos + dir * 1000.0, duration)
	plane_tween.tween_property( %Shadow, "global_position", end_pos + dir * 1000.0 + shadow_offset, duration)
	plane_tween.chain()
	plane_tween.tween_callback( func() -> void :
		visible = false
		finished.emit()
		)
	var shoot_tween: = create_tween()
	shoot_tween.tween_callback( func() -> void :
		%MuzzleFire.visible = true
		%ShootingAudio.play()
		%SmokeParticles.emitting = true
		).set_delay(delay)
	shoot_tween.tween_callback( func() -> void :
		%MuzzleFire.visible = false
		).set_delay(shooting_time)
	shoot_tween.tween_callback( func() -> void :
		shooting_done.emit()
		).set_delay(bullet_delay)

	%MuzzleFire.play(&"default")

	var ortho: = dir.orthogonal()
	fire_rate = bullet_count / shooting_time

	explosion_timers.resize(bullet_count)
	explosion_timers.fill(bullet_delay)
	targets.resize(bullet_count)
	for i: int in bullet_count:
		targets[i] = start_pos + dir * length * (float(i) / bullet_count) + dir * randf_range(-10.0, 10.0) + ortho * randf_range(-0.5, 0.5) * width


func _physics_process(delta: float) -> void :
	total_time += delta
	if total_time < delay:
		return

	delta += delta_overflow

	var spawn_amount: int = floori(delta * fire_rate)
	delta_overflow = delta - spawn_amount / fire_rate
	spawn_amount = min(bullet_count - bullets_spawned, spawn_amount)
	if bullets_spawned < bullet_count && spawn_amount > 0:
		var bullets: Array[Rigidbody] = []
		bullets.resize(spawn_amount)
		for i: int in spawn_amount:
			var target_pos: = targets[bullets_spawned]
			var bullet_start_pos: Vector2 = %MuzzleFire.global_position
			var bullet_to_target: = target_pos - bullet_start_pos
			var bullet: Rigidbody = Rigidbody.new(bullet_start_pos, bullet_to_target / bullet_delay, 1.0, 1.0, 1.0)
			bullet.layer = Rigidbody.Layers.PROJECTILES
			bullet.lifetime = bullet_delay
			bullets[i] = bullet
			bullets_spawned += 1

		GPUSim.add_rigidbodies(bullets)

	var explosion_radius: = StrafingRun.get_radius()
	for i: int in bullets_spawned:
		if i < explosions_spawned:
			continue
		explosion_timers[i] -= delta
		if explosion_timers[i] > 0.0:
			continue

		var target_pos: = targets[explosions_spawned]

		var expl: Rigidbody = Rigidbody.new(target_pos, Vector2.ZERO, explosion_radius, 1.0 / push_force, 0.0)
		expl.layer = Rigidbody.Layers.EXPLOSIONS
		expl.sensor_mask = Rigidbody.Layers.ENEMIES
		expl.lifetime = 0.0
		expl.ch_damage_other = StrafingRun.get_damage()
		expl.ch_damage_falloff = 1.0
		expl.ch_flags = 0
		expl.ch_damage_report_id = Constants.DAMAGE_REPORT_ID_STRAFING_RUN
		GPUSim.add_rigidbodies([expl])

		explosions_spawned += 1

	if explosions_spawned > 0:
		if !audio_player:
			audio_player = AudioManager.play_sound_at(Constants.strafing_run_explosions_sound, start_pos, 0.0, 1.0)

		var rel_shooting_time: = float(explosions_spawned) / bullet_count
		audio_player.global_position = start_pos + to_target * rel_shooting_time
