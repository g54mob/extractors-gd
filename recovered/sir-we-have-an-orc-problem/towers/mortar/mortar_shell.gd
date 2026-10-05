class_name MortarShell
extends AnimatedSprite2D


var target_pos: Vector2
var time_to_target: float
var explosion_damage: float = 1.0
var explosion_radius: float = 16.0
var fragment_count: int = 0
var fragment_damage: float = 0.0
var fragment_penetration: float = 1.0

var battle: Battle

func _ready() -> void :
	var sprite_tween: = create_tween()
	sprite_tween.tween_property(self, "frame", 5, time_to_target)

	var to_target: = target_pos - global_position
	rotation = to_target.normalized().angle()
	var half_pos: = global_position + to_target * 0.5
	var half_time: = time_to_target * 0.5
	scale = Vector2.ONE * 0.25

	var tween: = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "global_position", half_pos, half_time).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector2.ONE, half_time).set_ease(Tween.EASE_OUT)
	tween.chain()
	tween.tween_property(self, "global_position", target_pos, half_time).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE * 0.25, half_time).set_ease(Tween.EASE_IN)
	tween.chain()
	tween.tween_callback(explode)


func explode() -> void :
	var push_force: = 500.0

	var expl: Rigidbody = Rigidbody.new(target_pos, Vector2.ZERO, explosion_radius, 1.0 / push_force, 0.0)
	expl.layer = Rigidbody.Layers.EXPLOSIONS
	expl.sensor_mask = Rigidbody.Layers.ENEMIES
	expl.lifetime = 0.0
	expl.ch_damage_other = explosion_damage
	expl.ch_damage_falloff = 1.0
	expl.ch_flags = 0
	expl.ch_damage_report_id = Constants.DAMAGE_REPORT_ID_MORTAR
	GPUSim.add_rigidbodies([expl])

	if fragment_count > 0:
		var expl_fragments: Array[Rigidbody] = []
		expl_fragments.resize(fragment_count)
		for i: int in fragment_count:
			var angle: = PI * 2.0 * randf()
			var vel: = Vector2.from_angle(angle) * 300.0
			var frag: Rigidbody = Rigidbody.new(target_pos, vel, 0.5, 0.5, fragment_penetration)
			frag.layer = Rigidbody.Layers.PROJECTILES
			frag.sensor_mask = Rigidbody.Layers.ENEMIES | Rigidbody.Layers.TERRAIN
			frag.collision_mask = 0
			frag.lifetime = 0.5
			frag.ch_damage_self = 1.0
			frag.ch_damage_other = fragment_damage
			frag.ch_damage_falloff = 0.0
			frag.ch_flags = Rigidbody.ContactHandlerFlags.KILL_IF_OTHER_TERRAIN
			frag.ch_damage_report_id = Constants.DAMAGE_REPORT_ID_MORTAR
			expl_fragments[i] = frag
		GPUSim.add_rigidbodies(expl_fragments)

	AudioManager.play_sound_at(Constants.explosion_sound, target_pos, 0.0, randf_range(0.9, 1.1) * clampf(10.0 / log(explosion_radius), 0.5, 2.0))
	queue_free()
