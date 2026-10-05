class_name Flamethrower
extends BaseTower

@export_category("Visuals")
@export var rotatable: Node2D
@export var spawn_pos_base: Marker2D
@export var min_angle: float = 2.0
@export var max_angle: float = 60.0

const BASE_FIRE_TIMER: float = 1.0
const BASE_RANGE: float = 25.0

const BASE_FIRE_TICK_RATE: float = 1.0
const BASE_FIRE_TICK_DAMAGE: float = 0.1
const FLAME_SPEED: float = 100.0

static func get_fire_tick_rate() -> float:
	return (BASE_FIRE_TICK_RATE
		+ TechTree.get_upgrade(&"fire_tick_rate").current_value)

static func get_fire_tick_damage() -> float:
	return (BASE_FIRE_TICK_DAMAGE
		+ TechTree.get_upgrade(&"fire_tick_damage").current_value)

static func get_fire_timer() -> float:
	return (BASE_FIRE_TIMER
		+ TechTree.get_upgrade(&"flamethrower_fire_duration").current_value)

static func get_range() -> float:
	return (BASE_RANGE
		+ TechTree.get_upgrade(&"flamethrower_range").current_value)

static func get_free_penetration_chance() -> float:
	return (TechTree.get_upgrade(&"fire_free_penetration").current_value
		+ TechTree.get_upgrade(&"fire_free_penetration_2").current_value)

static func get_damage_multiplier_percentage() -> int:
	return int(TechTree.get_upgrade(&"fire_damage_buff").current_value
		+ TechTree.get_upgrade(&"fire_damage_buff_2").current_value)

static func get_damage_multiplier() -> float:
	return 1.0 + (get_damage_multiplier_percentage() / 100.0)

var base_rotation_degrees: float = 0.0
var move_rotation_degrees: float = 0.0

var delta_overflow: float = 0.0
var total_time: float = 0.0

static func get_kind() -> TowerKind:
	return TowerKind.FLAMETHROWER

static func is_unlocked() -> bool:
	return is_tower_unlocked(get_kind())

static func get_tower_limit(_tower_kind: BaseTower.TowerKind) -> int:
	return int(1
		+ TechTree.get_upgrade(&"flamethrower_count").current_value
		+ TechTree.get_upgrade(&"flamethrower_count_2").current_value
		+ TechTree.get_upgrade(&"flamethrower_count_3").current_value
	)

static func get_icon(_tower_kind: BaseTower.TowerKind) -> Texture2D:
	return load("res://towers/flamethrower/flamethrower_icon.png")

static func _create_from_data(data: Dictionary) -> BaseTower:
	var ft: Flamethrower = load(BaseTower.TOWER_SCENES[get_kind()]).instantiate()
	ft.global_position = Vector2(data["position"]["x"], data["position"]["y"])
	if data.has("target_pos"):
		ft.target_pos = Vector2(data["target_pos"]["x"], data["target_pos"]["y"])
	else:
		ft.target_pos = ft.global_position + Vector2.RIGHT * 100.0
	return ft

func save_to_data() -> Dictionary:
	return {
		"kind": TowerKind.keys()[get_kind()], 
		"position": {"x": global_position.x, "y": global_position.y}, 
		"target_pos": {"x": target_pos.x, "y": target_pos.y}, 
	}

var target_preview_points: PackedVector2Array

var flame_lifetime: float = 0.5
var fire_rate: float = 30.0
var fire_range: float = BASE_RANGE
var fire_timer: float = BASE_FIRE_TIMER
var free_penetration_chance: float = 0.0

func _ready() -> void :
	super._ready()

	total_time += randf_range(0.0, PI * 2.0)

	delta_overflow = randf_range(0.0, 1.0 / fire_rate) * 0.5

	fire_range = get_range()
	fire_timer = get_fire_timer()
	flame_lifetime = fire_range / FLAME_SPEED


	on_edit_mode_changed()
	target_preview_points.resize(10)
	target_preview_points.fill(Vector2.ZERO)
	if target_pos == Vector2.ZERO:
		target_pos = global_position + Vector2.RIGHT * Constants.TARGET_MIN_DISTANCE
		target.global_position = target_pos
	update_targeting()
	rotatable.rotation_degrees = base_rotation_degrees
	%SpreadPreview.rotation_degrees = base_rotation_degrees

	battle.phase_changed.connect(_on_battle_phase_changed)

func on_edit_mode_changed() -> void :
	super.on_edit_mode_changed()
	%SpreadPreview.modulate.a = 1.0 if edit_mode == EditMode.EDIT_TARGET else 0.2
	%SpreadPreview.visible = battle.phase == Battle.Phase.BUILD and was_constructed

func _on_battle_phase_changed(_new_phase: Battle.Phase) -> void :
	%SpreadPreview.visible = battle.phase == Battle.Phase.BUILD and was_constructed
	target.visible = battle.phase == Battle.Phase.BUILD and edit_mode == EditMode.EDIT_TARGET
	if battle.phase == Battle.Phase.BATTLE:
		%AudioPlayer.play()

func _physics_process(delta: float) -> void :
	if edit_mode == EditMode.MOVABLE:
		super._physics_process(delta)

	if battle.phase != Battle.Phase.BATTLE:
		return

	total_time += delta
	var base_spawn_angle: float = (base_rotation_degrees + sin(total_time) * move_rotation_degrees) * DEGREES_TO_RADIANS
	rotatable.rotation = base_spawn_angle

	delta += delta_overflow
	var spawn_amount: int = floori(delta * fire_rate)
	delta_overflow = delta - spawn_amount / fire_rate

	if spawn_amount == 0:
		return

	var radius: = 4.0
	var spread: = 2.0
	var body_array: Array[Rigidbody] = []
	body_array.resize(spawn_amount)
	for i: int in spawn_amount:
		var angle: float = (base_rotation_degrees + sin(total_time) * move_rotation_degrees + randf_range( - spread, spread)) * DEGREES_TO_RADIANS
		var dir: = Vector2.from_angle(angle)
		var pos: Vector2 = spawn_pos_base.global_position
		var vel: = dir * FLAME_SPEED
		var body: Rigidbody = Rigidbody.new(pos, vel, radius, 0.0001, 1.0)
		body.layer = Rigidbody.Layers.FLAMES
		body.sensor_mask = Rigidbody.Layers.ENEMIES | Rigidbody.Layers.TERRAIN

		body.lifetime = flame_lifetime - randf() * 0.05
		body.ch_fire_timer = fire_timer
		body.ch_flags = Rigidbody.ContactHandlerFlags.KILL_IF_OTHER_TERRAIN
		body_array[i] = body

	GPUSim.add_rigidbodies(body_array)


func update_targeting() -> void :
	var to_target: = target_pos - global_position
	var dir: = to_target.normalized()
	var base_rotation: = dir.angle()
	base_rotation_degrees = base_rotation * 180.0 / PI

	var len_to_target: = to_target.length()
	move_rotation_degrees = lerpf(max_angle, min_angle, clampf(remap(sqrt(len_to_target), sqrt(Constants.TARGET_MIN_DISTANCE), sqrt(Constants.TARGET_MAX_DISTANCE), 0.0, 1.0), 0.0, 1.0))

	var display_range: = fire_range / scale.x
	var start_angle: = - move_rotation_degrees * DEGREES_TO_RADIANS
	var angle_step: = 2.0 * move_rotation_degrees * DEGREES_TO_RADIANS / (target_preview_points.size() - 2)

	for i: int in target_preview_points.size() - 1:
		var point: = Vector2.from_angle(start_angle + angle_step * i) * display_range
		target_preview_points[i] = point

	%SpreadPreview.points = target_preview_points

func _unhandled_input(event: InputEvent) -> void :
	super._unhandled_input(event)
	if edit_mode == EditMode.EDIT_TARGET:
		if event is InputEventMouseMotion:
			target_pos = clamp_target_pos(get_global_mouse_position())
			update_targeting()
			rotatable.rotation_degrees = base_rotation_degrees
			%SpreadPreview.rotation_degrees = base_rotation_degrees
			target.global_position = target_pos

	elif edit_mode == EditMode.MOVABLE and was_constructed:
		if event is InputEventMouseMotion:
			target_pos = clamp_target_pos(target_pos)
			update_targeting()
			rotatable.rotation_degrees = base_rotation_degrees
			%SpreadPreview.rotation_degrees = base_rotation_degrees
			target.global_position = target_pos
