class_name MinigunRobot
extends BaseTower

@export_category("Visuals")
@export var rotatable: Node2D
@export var spawn_pos_bases: Array[Marker2D]
@export var muzzle_flashes: Array[AnimatedSprite2D]
@export var spawn_width: float = 2.0
@export var spread_degrees: float = 5.0
@export var move_rotation_degrees: float = 10.0

const BASE_BULLET_DAMAGE: float = 1.0
const BASE_BULLET_FIRE_RATE: float = 50.0
const BASE_BULLET_MASS: float = 2.0
const BASE_BULLET_HEALTH: float = 2.0
const BASE_BULLET_SPEED: float = 300.0
const BASE_BULLET_RADIUS: float = 0.75

static func get_damage() -> float:
	return (BASE_BULLET_DAMAGE


	)

static func get_firerate() -> float:
	return (BASE_BULLET_FIRE_RATE

	)

var base_rotation_degrees: float = 0.0;

var fire_rate: float = BASE_BULLET_FIRE_RATE
var bullet_mass: float = BASE_BULLET_MASS


var bullet_health: float = BASE_BULLET_HEALTH
var bullet_speed: float = BASE_BULLET_SPEED
var bullet_radius: float = BASE_BULLET_RADIUS

var total_bullets_spawned: int = 0

func _ready() -> void :
	super._ready()
	total_time += randf_range(0.0, PI * 2.0)
	for mf: AnimatedSprite2D in muzzle_flashes:
		mf.play(&"default")

	fire_rate = get_firerate()

	var spread: = Vector2.from_angle((move_rotation_degrees + spread_degrees) * DEGREES_TO_RADIANS) * 100.0
	%SpreadPreview.polygon[1] = spread * Vector2(1.0, -1.0)
	%SpreadPreview.polygon[2] = spread

	on_edit_mode_changed()
	rotatable.rotation_degrees = base_rotation_degrees
	%SpreadPreview.rotation_degrees = base_rotation_degrees
	battle.phase_changed.connect(_on_battle_phase_changed)

func _on_edit_mode_changed() -> void :
	super.on_edit_mode_changed()
	%SpreadPreview.modulate.a = 1.0 if edit_mode == EditMode.EDIT_TARGET else 0.5
	%SpreadPreview.visible = battle.phase == Battle.Phase.BUILD and was_constructed

func _on_battle_phase_changed(_new_phase: Battle.Phase) -> void :
	%SpreadPreview.visible = battle.phase == Battle.Phase.BUILD and was_constructed

static func get_kind() -> TowerKind:
	return TowerKind.MINIGUN_ROBOT

static func get_tower_limit(_tower_kind: BaseTower.TowerKind) -> int:
	return int(1


	)

static func get_icon(_tower_kind: BaseTower.TowerKind) -> Texture2D:
	return load("res://towers/minigun_robot/minigun_robot.png")

static func _create_from_data(data: Dictionary) -> BaseTower:
	var minigun_robot: MinigunRobot = load(BaseTower.TOWER_SCENES[get_kind()]).instantiate()
	minigun_robot.global_position = Vector2(data["position"]["x"], data["position"]["y"])
	minigun_robot.base_rotation_degrees = data["rotation_degrees"]
	return minigun_robot

func save_to_data() -> Dictionary:
	return {
		"kind": TowerKind.keys()[get_kind()], 
		"position": {"x": global_position.x, "y": global_position.y}, 
		"rotation_degrees": base_rotation_degrees, 
	}

var delta_overflow: float = 0.0
var total_time: float = 0.0
func _physics_process(delta: float) -> void :
	total_time += delta
	var base_spawn_angle: float = (base_rotation_degrees + sin(total_time) * move_rotation_degrees) * DEGREES_TO_RADIANS
	rotatable.rotation = base_spawn_angle

	delta += delta_overflow
	var spawn_amount: int = floori(delta * fire_rate)
	delta_overflow = delta - spawn_amount / fire_rate

	if spawn_amount == 0:
		return

	var base_dir: = Vector2(cos(base_spawn_angle), sin(base_spawn_angle))
	var width_dir: = base_dir.orthogonal() * spawn_width

	var body_array: Array[Rigidbody] = []
	body_array.resize(spawn_amount)
	for i: int in spawn_amount:
		var spawn_pos_base: Marker2D = spawn_pos_bases[total_bullets_spawned % spawn_pos_bases.size()]
		var base_spawn_pos: Vector2 = spawn_pos_base.global_position
		var pos: = base_spawn_pos + width_dir * randf_range(-1.0, 1.0)
		var spawn_angle: = base_spawn_angle + randf_range(-1.0, 1.0) * spread_degrees * DEGREES_TO_RADIANS
		var vel: = Vector2.from_angle(spawn_angle) * bullet_speed
		pos += vel * delta * (float(i) / spawn_amount)
		var radius: = bullet_radius
		var mass: = bullet_mass
		var health: = bullet_health
		var body: Rigidbody = Rigidbody.new(pos, vel, radius, 1.0 / mass, health)
		body.layer = Rigidbody.Layers.PROJECTILES
		body.sensor_mask = Rigidbody.Layers.ENEMIES | Rigidbody.Layers.TERRAIN
		body.collision_mask = 0
		body.lifetime = 0.5
		body.ch_damage_self = 1.0
		body.ch_damage_other = get_damage()
		body.ch_flags = Rigidbody.ContactHandlerFlags.KILL_IF_OTHER_TERRAIN
		body_array[i] = body
		total_bullets_spawned += 1

	GPUSim.add_rigidbodies(body_array)

func _unhandled_input(event: InputEvent) -> void :
	super._unhandled_input(event)
	if edit_mode == EditMode.EDIT_TARGET:
		if event is InputEventMouseMotion:
			var dir: = (get_global_mouse_position() - global_position).normalized()
			base_rotation_degrees = dir.angle() * 180.0 / PI
			rotatable.rotation_degrees = base_rotation_degrees
			%SpreadPreview.rotation_degrees = base_rotation_degrees
