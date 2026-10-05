class_name ExplosionSprite
extends Node2D

@export var radius: float = 8.0
@export var max_life_time: float = 0.1
var life_time: float = 0.0

@onready var fire_sprite: Sprite2D = %FireSprite
@onready var smoke_particles: GPUParticles2D = %SmokeParticles

func _ready() -> void :
	fire_sprite.scale = Vector2.ONE * radius * 2.0
	smoke_particles.amount = ceili(radius * PI)
	smoke_particles.emitting = true
	smoke_particles.finished.connect(queue_free)
	var mat: = smoke_particles.process_material as ParticleProcessMaterial
	mat.emission_sphere_radius = radius * 0.5
	mat.radial_velocity_min = radius * 1.8
	mat.radial_velocity_max = radius * 2.0
	mat.damping_min = mat.radial_velocity_max * 2.0
	mat.damping_max = mat.radial_velocity_max * 2.0

func _process(delta: float) -> void :
	life_time += delta
	if fire_sprite:
		if life_time >= max_life_time:
			fire_sprite.queue_free()
		else:
			fire_sprite.set_instance_shader_parameter("life_time_factor", life_time / max_life_time)
