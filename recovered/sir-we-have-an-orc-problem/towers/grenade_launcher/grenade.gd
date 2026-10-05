class_name Grenade
extends Sprite2D


var target_pos: Vector2
var speed: float
var explosion_damage: float = 1.0
var explosion_radius: float = 16.0
var fragment_count: int = 0
var fragment_damage: float = 0.0
var fragment_penetration: float = 1.0

var distance: float
var to_target: Vector2

var battle: Battle

const BASE_SCALE: = Vector2.ONE * 0.25

func _ready() -> void :

	to_target = target_pos - global_position
	distance = to_target.length()
	rotation = to_target.normalized().angle()
	var half_pos: = global_position + to_target * 0.5
	var time_to_target: = distance / speed
	var half_time: = time_to_target * 0.5

	scale = BASE_SCALE

	var tween: = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "global_position", half_pos, half_time)
	tween.tween_property(self, "scale", BASE_SCALE * (1.0 + log(max(distance / 100.0, 1.0))), half_time).set_ease(Tween.EASE_OUT)
	tween.chain()
	tween.tween_property(self, "global_position", target_pos, half_time).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", BASE_SCALE, half_time)
	tween.chain()
	tween.tween_callback(explode)


func explode() -> void :
	var vel: = to_target.normalized() * speed
	var grenade: = Rigidbody.new(target_pos, vel, 1.0, 1.0 / 50.0, 1.0)
	grenade.layer = Rigidbody.Layers.GRENADES
	grenade.collision_mask = Rigidbody.Layers.ENEMIES | Rigidbody.Layers.EXPLOSIONS | Rigidbody.Layers.GRENADES | Rigidbody.Layers.TERRAIN
	grenade.lifetime = GrenadeLauncher.get_grenade_lifetime()

	GPUSim.add_rigidbodies([grenade])

	queue_free()
