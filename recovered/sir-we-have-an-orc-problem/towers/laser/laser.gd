class_name Laser
extends BaseTower

@export_category("Visuals")
@export var rotatable: Node2D
@export var spawn_pos_base: Marker2D
@export var min_angle: float = 2.0
@export var max_angle: float = 60.0

const BASE_RANGE: float = 100.0
var fire_range: = BASE_RANGE
static func get_range() -> float:
	return (BASE_RANGE
		+ TechTree.get_upgrade(&"laser_range").current_value
		+ TechTree.get_upgrade(&"laser_range_2").current_value
		+ TechTree.get_upgrade(&"laser_range_3").current_value)

const BASE_FIRE_RATE: float = 0.5
var fire_rate: = BASE_FIRE_RATE
static func get_fire_rate() -> float:
	return (BASE_FIRE_RATE
		+ TechTree.get_upgrade(&"laser_firerate").current_value
		+ TechTree.get_upgrade(&"laser_firerate_2").current_value)

const BASE_MAX_BOUNCES: int = 5
var max_bounces: = BASE_MAX_BOUNCES
static func get_max_bounces() -> int:
	return int(BASE_MAX_BOUNCES
		+ TechTree.get_upgrade(&"laser_bounces").current_value
		+ TechTree.get_upgrade(&"laser_bounces_2").current_value)

const BASE_DAMAGE: float = 1.5
static func get_damage() -> float:
	return (BASE_DAMAGE
		+ TechTree.get_upgrade(&"laser_damage").current_value
		+ TechTree.get_upgrade(&"laser_damage_2").current_value
		+ TechTree.get_upgrade(&"laser_damage_3").current_value
		+ TechTree.get_upgrade(&"laser_damage_4").current_value)

var base_rotation_degrees: float = 0.0
var move_rotation_degrees: float = 0.0

var delta_overflow: float = 0.0
var total_time: float = 0.0

static func get_kind() -> TowerKind:
	return TowerKind.LASER

static func is_unlocked() -> bool:
	return is_tower_unlocked(get_kind())

static func get_tower_limit(_tower_kind: BaseTower.TowerKind) -> int:
	return int(1
		+ TechTree.get_upgrade(&"laser_count").current_value
		+ TechTree.get_upgrade(&"laser_count_2").current_value
		+ TechTree.get_upgrade(&"laser_count_3").current_value
	)

static func get_icon(_tower_kind: BaseTower.TowerKind) -> Texture2D:
	return load("res://towers/laser/laser_icon.png")

static func _create_from_data(data: Dictionary) -> BaseTower:
	var laser: Laser = load(BaseTower.TOWER_SCENES[get_kind()]).instantiate()
	laser.global_position = Vector2(data["position"]["x"], data["position"]["y"])
	if data.has("target_pos"):
		laser.target_pos = Vector2(data["target_pos"]["x"], data["target_pos"]["y"])
	else:
		laser.target_pos = laser.global_position + Vector2.RIGHT * 100.0
	return laser

func save_to_data() -> Dictionary:
	return {
		"kind": TowerKind.keys()[get_kind()], 
		"position": {"x": global_position.x, "y": global_position.y}, 
		"target_pos": {"x": target_pos.x, "y": target_pos.y}, 
	}

var target_preview_points: PackedVector2Array

func _ready() -> void :
	super._ready()

	total_time += randf_range(0.0, PI * 2.0)
	fire_range = get_range()
	fire_rate = get_fire_rate()
	max_bounces = get_max_bounces()

	delta_overflow += (1.0 / fire_rate) * randf()

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

	%LaserLine.clear_points()
	var remaining_range: = fire_range
	var space_state: = get_world_2d().direct_space_state
	var from: Vector2 = spawn_pos_base.global_position
	var point_query: = PhysicsPointQueryParameters2D.new()
	point_query.collision_mask = 1 << 4
	point_query.collide_with_areas = true
	point_query.canvas_instance_id = get_tree().get_first_node_in_group("world_layer").get_instance_id()
	point_query.position = spawn_pos_base.global_position
	var from_collider_id: int = -1
	var initial_collider_result: = space_state.intersect_point(point_query, 4)
	if !initial_collider_result.is_empty():
		from_collider_id = initial_collider_result[0].collider_id
	var dir: Vector2 = Vector2.from_angle(base_spawn_angle)
	var segments: Array[Vector4] = []
	%LaserLine.add_point(to_local(from))
	var bounces: int = 0
	while remaining_range > 0.0 and bounces < max_bounces:
		var to: Vector2 = from + dir * remaining_range
		var query: = PhysicsRayQueryParameters2D.create(from, to, 1 << 4)
		query.collide_with_areas = true
		var result: = space_state.intersect_ray(query)
		if !result.is_empty():
			var hit_point: Vector2 = result.position
			var distance: float = (hit_point - from).length()
			remaining_range -= distance + 0.2
			if result.collider_id == from_collider_id:
				point_query.position = hit_point - dir * 0.1
				var empty_collider_test: = space_state.intersect_point(point_query, 1)
				if !empty_collider_test.is_empty():
					from = hit_point + dir * 0.2
					continue
			from_collider_id = -1
			segments.append(Vector4(from.x, from.y, hit_point.x, hit_point.y))
			%LaserLine.add_point(to_local(hit_point))

			var hit_normal: Vector2 = result.normal

			dir = dir.bounce(hit_normal)
			from = hit_point + dir * 0.2
			bounces += 1
		else:

			var ws: = Vector2(battle.world_data.world_size)
			var travelled: Vector2 = abs(to - from)
			var to_lower_boundary: Vector2 = from - Vector2.ZERO
			var to_upper_boundary: Vector2 = ws - from
			var t_to_lower: Vector2 = to_lower_boundary / travelled
			var t_to_upper: Vector2 = to_upper_boundary / travelled
			var min_t: float = min(1.0, t_to_lower.x if dir.x <= 0.0 else t_to_upper.x, t_to_lower.y if dir.y <= 0.0 else t_to_upper.y)
			var end: Vector2 = from + dir * (min_t * remaining_range)

			segments.append(Vector4(from.x, from.y, end.x, end.y))
			%LaserLine.add_point(to_local(end))
			remaining_range = 0.0

	%LaserLine.width = 4.0
	var tween: = create_tween()
	tween.tween_property( %LaserLine, "width", 0.0, 0.4).set_ease(Tween.EASE_IN)

	GPUSim.add_laser_segments(segments)

	%AudioPlayer.play()


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
