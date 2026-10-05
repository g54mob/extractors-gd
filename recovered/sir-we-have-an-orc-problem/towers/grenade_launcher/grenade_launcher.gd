class_name GrenadeLauncher
extends BaseTower

@export_category("Visuals")
@export var rotatable: Node2D
@export var spawn_pos_base: Marker2D
@export var base_target_radius: float = 20.0
@export var distance_radius_modifier: float = 100.0

var reload_timer: float = 0.0
var volley_size: int = 8
var grenades_loaded: int = 0

var delta_overflow: float = 0.0

var target_radius: float = 0.0
var dist_to_target: float = 0.0

var base_target_preview_scale: Vector2 = Vector2.ONE
var next_target_pos: Vector2

const BASE_VOLLEY_SIZE: int = 1
const BASE_RELOAD_TIME: float = 1.5
const BASE_GRENADE_LIFETIME: float = 2.0
const BASE_GRENADE_RADIUS: float = 5.0
const BASE_SLOW_STRENGTH: float = 30.0
const BASE_SLOW_DURATION: float = 2.0
const BASE_EXPLOSION_DAMAGE: float = 2.0
const BASE_EXPLOSION_RADIUS: float = 8.0
const BASE_EXPLOSION_PUSH_FORCE: float = 100.0
const BASE_VOLLEY_FIRE_RATE: float = 10.0
const BASE_GRENADE_SPEED: float = 100.0

static func get_volley_size() -> int:
	return roundi(BASE_VOLLEY_SIZE
		+ TechTree.get_upgrade(&"grenade_launcher_volley").current_value
	)

static func get_grenade_lifetime() -> float:
	return (BASE_GRENADE_LIFETIME
		+ TechTree.get_upgrade(&"grenade_launcher_lifetime").current_value
	)

static func get_grenade_radius() -> float:
	return (BASE_GRENADE_RADIUS
		+ TechTree.get_upgrade(&"grenade_launcher_radius").current_value
	)

static func get_slow_strength() -> float:
	return (BASE_SLOW_STRENGTH
		+ TechTree.get_upgrade(&"grenade_launcher_slow_strength").current_value
		+ TechTree.get_upgrade(&"grenade_launcher_slow_strength_2").current_value
	)

static func get_slow_duration() -> float:
	return (BASE_SLOW_DURATION
		+ TechTree.get_upgrade(&"grenade_launcher_slow_duration").current_value
	)

static func get_explosion_damage() -> float:
	return (BASE_EXPLOSION_DAMAGE
		+ TechTree.get_upgrade(&"grenade_launcher_explosion_damage").current_value
		+ TechTree.get_upgrade(&"grenade_launcher_explosion_damage_2").current_value
	) * TechTree.get_upgrade(&"grenade_launcher_explosive").level

static func get_explosion_radius() -> float:
	return (BASE_EXPLOSION_RADIUS
		+ TechTree.get_upgrade(&"grenade_launcher_explosion_radius").current_value
	)

static func get_damage_multiplier_percentage() -> int:
	return int(TechTree.get_upgrade(&"grenade_launcher_damage_buff").current_value
		+ TechTree.get_upgrade(&"grenade_launcher_damage_buff_2").current_value)

static func get_damage_multiplier() -> float:
	return 1.0 + (get_damage_multiplier_percentage() / 100.0)

var explosion_damage: = BASE_EXPLOSION_DAMAGE
var explosion_radius: = BASE_EXPLOSION_RADIUS

var target_preview_points: = PackedVector2Array()

func _ready() -> void :
	super._ready()
	volley_size = get_volley_size()

	base_target_preview_scale = (Vector2.ONE / scale)
	reload_timer = BASE_RELOAD_TIME * randf_range(0.5, 1.0)

	explosion_damage = get_explosion_damage()
	explosion_radius = get_explosion_radius()

	target_preview_points.resize(32)
	on_edit_mode_changed()
	_update_from_target_pos()
	battle.phase_changed.connect(_on_battle_phase_changed)
	%MuzzleFlashAnimatedSprite.visible = false
	%MuzzleFlashAnimatedSprite.animation_finished.connect( %MuzzleFlashAnimatedSprite.set_visible.bind(false))

func on_edit_mode_changed() -> void :
	super.on_edit_mode_changed()
	%TargetPreview.modulate.a = 1.0 if edit_mode == EditMode.EDIT_TARGET else 0.2
	%TargetPreview.visible = battle.phase == Battle.Phase.BUILD and was_constructed

	%TargetPreviewLine.modulate.a = %TargetPreview.modulate.a
	%TargetPreviewLine.visible = %TargetPreview.visible
	if edit_mode == EditMode.EDIT_TARGET:
		_update_from_target_pos()

func _on_battle_phase_changed(_new_phase: Battle.Phase) -> void :
	target.visible = battle.phase == Battle.Phase.BUILD and was_constructed
	%TargetPreview.visible = battle.phase == Battle.Phase.BUILD and was_constructed
	%TargetPreviewLine.visible = %TargetPreview.visible


static func get_kind() -> TowerKind:
	return TowerKind.GRENADE_LAUNCHER

static func is_unlocked() -> bool:
	return is_tower_unlocked(get_kind())

static func get_tower_limit(_tower_kind: BaseTower.TowerKind) -> int:
	return int(1
		+ TechTree.get_upgrade(&"grenade_launcher_count").current_value
		+ TechTree.get_upgrade(&"grenade_launcher_count_2").current_value
	)

static func get_icon(_tower_kind: BaseTower.TowerKind) -> Texture2D:
	return load("res://towers/grenade_launcher/grenade_launcher_icon.png")

static func _create_from_data(data: Dictionary) -> BaseTower:
	var grenade_launcher: GrenadeLauncher = load(BaseTower.TOWER_SCENES[get_kind()]).instantiate()
	grenade_launcher.global_position = Vector2(data["position"]["x"], data["position"]["y"])
	grenade_launcher.target_pos = Vector2(data["target_pos"]["x"], data["target_pos"]["y"])
	return grenade_launcher

func save_to_data() -> Dictionary:
	return {
		"kind": TowerKind.keys()[get_kind()], 
		"position": {"x": global_position.x, "y": global_position.y}, 
		"target_pos": {"x": target_pos.x, "y": target_pos.y}, 
	}

func _process(delta: float) -> void :
	if battle.phase != Battle.Phase.BATTLE:
		return
	var angle_to_target: = Vector2.from_angle(rotatable.global_rotation).angle_to(next_target_pos - rotatable.global_position)
	rotatable.global_rotation += delta * 5.0 * angle_to_target

func _physics_process(delta: float) -> void :
	if edit_mode == EditMode.MOVABLE:
		super._physics_process(delta)

	if battle.phase != Battle.Phase.BATTLE:
		return

	if grenades_loaded == 0:
		reload_timer -= delta
		if reload_timer <= 0.0:
			reload_timer = BASE_RELOAD_TIME
			grenades_loaded = volley_size
			delta_overflow = 0.0
		else:
			return

	delta += delta_overflow
	var spawn_amount: int = floori(delta * BASE_VOLLEY_FIRE_RATE)
	spawn_amount = min(grenades_loaded, spawn_amount)
	delta_overflow = delta - spawn_amount / BASE_VOLLEY_FIRE_RATE

	if spawn_amount == 0 or grenades_loaded == 0:
		return

	grenades_loaded -= spawn_amount

	for i: int in spawn_amount:
		var grenade: Grenade = Constants.grenade_scene.instantiate()
		grenade.battle = battle
		grenade.speed = BASE_GRENADE_SPEED
		grenade.global_position = spawn_pos_base.global_position
		grenade.target_pos = next_target_pos

		grenade.explosion_damage = explosion_damage
		grenade.explosion_radius = explosion_radius

		get_parent().get_parent().add_child(grenade)

	var target_angle: = PI * 2.0 * randf()
	var center_dist: = target_radius * sqrt(randf())
	next_target_pos = target_pos + Vector2.from_angle(target_angle) * center_dist

	%MuzzleFlashAnimatedSprite.visible = true
	%MuzzleFlashAnimatedSprite.play("default")

	AudioManager.play_sound_at(Constants.grenade_launcher_sound, global_position, 0.0, randf_range(0.8, 0.85))

func _update_from_target_pos() -> void :

	rotatable.rotation = (target_pos - global_position).angle()
	var to_target: = target_pos - spawn_pos_base.global_position
	dist_to_target = to_target.length()
	target_radius = base_target_radius * (dist_to_target / distance_radius_modifier + 1.0)

	target.global_position = target_pos
	%TargetPreview.global_position = target_pos
	var angle_step: float = 2.0 * PI / target_preview_points.size()
	for i: int in target_preview_points.size():
		target_preview_points[i] = Vector2.from_angle(angle_step * i) * base_target_preview_scale * target_radius
	%TargetPreview.points = target_preview_points

	var line_end_pos: = Vector2(max(dist_to_target - target_radius - %TargetPreview.width * 0.5, 0.0), 0.0) * base_target_preview_scale
	%TargetPreviewLine.points[1] = line_end_pos

	var target_angle: = PI * 2.0 * randf()
	var center_dist: = target_radius * sqrt(randf())
	next_target_pos = target_pos + Vector2.from_angle(target_angle) * center_dist

func _unhandled_input(event: InputEvent) -> void :
	super._unhandled_input(event)
	if edit_mode == EditMode.EDIT_TARGET:
		if event is InputEventMouseMotion:
			target_pos = get_global_mouse_position()
			_update_from_target_pos()

	elif edit_mode == EditMode.MOVABLE and was_constructed:
		if event is InputEventMouseMotion:
			_update_from_target_pos()
