class_name Mortar
extends BaseTower

@onready var audio_player: AudioStreamPlayer2D = $AudioPlayer

@export_category("Visuals")
@export var rotatable: Node2D
@export var spawn_pos_base: Marker2D
@export var base_target_radius: float = 20.0
@export var distance_radius_modifier: float = 100.0

var base_rotation_degrees: float = 0.0;
var fire_rate: float = 0.5

var delta_overflow: float = 0.0

var target_radius: float = 0.0
var dist_to_target: float = 0.0

var base_target_preview_scale: Vector2 = Vector2.ONE

const BASE_EXPLOSION_DAMAGE: float = 2.0
const BASE_EXPLOSION_RADIUS: float = 8.0
const BASE_FIRE_RATE: float = 0.4
const BASE_FRAGMENT_COUNT: int = 0
const BASE_FRAGMENT_DAMAGE: float = 1.0
const BASE_FRAGMENT_HEALTH: float = 1.0

var explosion_damage: float = BASE_EXPLOSION_DAMAGE
var explosion_radius: float = BASE_EXPLOSION_RADIUS

var fragment_count: int = BASE_FRAGMENT_COUNT
var fragment_damage: float = BASE_FRAGMENT_DAMAGE
var fragment_health: float = BASE_FRAGMENT_HEALTH

static func get_explosion_damage() -> float:
	return (BASE_EXPLOSION_DAMAGE
		+ TechTree.get_upgrade(&"mortar_explosion_damage").current_value
		+ TechTree.get_upgrade(&"mortar_explosion_damage_2").current_value
	)

static func get_explosion_radius() -> float:
	return (BASE_EXPLOSION_RADIUS
		+ TechTree.get_upgrade(&"mortar_explosion_radius").current_value
	)

static func get_fragment_count() -> int:
	return int(BASE_FRAGMENT_COUNT
		+ TechTree.get_upgrade(&"mortar_fragment_count").current_value
		+ TechTree.get_upgrade(&"mortar_fragment_count_2").current_value
	)

static func get_fragment_damage() -> float:
	return (BASE_FRAGMENT_DAMAGE
		+ TechTree.get_upgrade(&"mortar_fragment_damage").current_value
	)

static func get_fragment_health() -> float:
	return (BASE_FRAGMENT_HEALTH
		+ TechTree.get_upgrade(&"mortar_fragment_penetration").current_value
	)

static func get_firerate() -> float:
	return (BASE_FIRE_RATE
		+ TechTree.get_upgrade(&"mortar_firerate").current_value
	)

var target_preview_points: = PackedVector2Array()

func _ready() -> void :
	super._ready()
	delta_overflow = randf_range(0.0, 1.0 / fire_rate) * 0.5

	fire_rate = get_firerate()
	explosion_damage = get_explosion_damage()
	explosion_radius = get_explosion_radius()
	fragment_count = get_fragment_count()
	fragment_damage = get_fragment_damage()
	fragment_health = get_fragment_health()

	base_target_preview_scale = (Vector2.ONE / scale)

	target_preview_points.resize(32)
	on_edit_mode_changed()
	_update_from_target_pos()
	battle.phase_changed.connect(_on_battle_phase_changed)

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
	return TowerKind.MORTAR

static func is_unlocked() -> bool:
	return is_tower_unlocked(get_kind())

static func get_tower_limit(_tower_kind: BaseTower.TowerKind) -> int:
	return int(1
		+ TechTree.get_upgrade(&"mortar_count").current_value
		+ TechTree.get_upgrade(&"mortar_count_2").current_value
		+ TechTree.get_upgrade(&"mortar_count_3").current_value
	)

static func get_icon(_tower_kind: BaseTower.TowerKind) -> Texture2D:
	return load("res://towers/mortar/mortar_icon.png")

static func _create_from_data(data: Dictionary) -> BaseTower:
	var mortar: Mortar = load(BaseTower.TOWER_SCENES[get_kind()]).instantiate()
	mortar.global_position = Vector2(data["position"]["x"], data["position"]["y"])
	mortar.target_pos = Vector2(data["target_pos"]["x"], data["target_pos"]["y"])
	return mortar

func save_to_data() -> Dictionary:
	return {
		"kind": TowerKind.keys()[get_kind()], 
		"position": {"x": global_position.x, "y": global_position.y}, 
		"target_pos": {"x": target_pos.x, "y": target_pos.y}, 
	}

func _physics_process(delta: float) -> void :
	if edit_mode == EditMode.MOVABLE:
		super._physics_process(delta)
	if battle.phase != Battle.Phase.BATTLE:
		return

	delta += delta_overflow
	var spawn_amount: int = floori(delta * fire_rate)
	delta_overflow = delta - spawn_amount / fire_rate



	if spawn_amount == 0:
		return

	for i: int in spawn_amount:
		var shell: MortarShell = Constants.mortar_shell_scene.instantiate()
		shell.battle = battle
		var target_angle: = PI * 2.0 * randf()
		var center_dist: = target_radius * sqrt(randf())
		shell.target_pos = target_pos + Vector2.from_angle(target_angle) * center_dist
		shell.time_to_target = 2.0 + dist_to_target / distance_radius_modifier
		shell.global_position = spawn_pos_base.global_position
		shell.explosion_damage = explosion_damage
		shell.explosion_radius = explosion_radius
		shell.fragment_count = fragment_count
		shell.fragment_damage = fragment_damage
		shell.fragment_penetration = fragment_health

		get_parent().get_parent().add_child(shell)

	audio_player.pitch_scale = randf_range(0.9, 1.1)
	audio_player.play()

func _update_from_target_pos() -> void :
	var to_target: = target_pos - spawn_pos_base.global_position
	var dir: = to_target.normalized()
	base_rotation_degrees = dir.angle() * 180.0 / PI
	rotatable.rotation_degrees = base_rotation_degrees
	dist_to_target = to_target.length()
	target_radius = base_target_radius * (dist_to_target / distance_radius_modifier + 1.0)

	target.global_position = target_pos
	%TargetPreview.global_position = target_pos
	var angle_step: float = 2.0 * PI / target_preview_points.size()
	for i: int in target_preview_points.size():
		target_preview_points[i] = Vector2.from_angle(angle_step * i) * base_target_preview_scale * target_radius
	%TargetPreview.points = target_preview_points

	var line_end_pos: Vector2 = spawn_pos_base.global_position + dir * max(dist_to_target - target_radius - %TargetPreview.width * 0.5, 0.0)
	%TargetPreviewLine.points[1] = to_local(line_end_pos)

func _unhandled_input(event: InputEvent) -> void :
	super._unhandled_input(event)
	if edit_mode == EditMode.EDIT_TARGET:
		if event is InputEventMouseMotion:
			target_pos = get_global_mouse_position()
			_update_from_target_pos()

	elif edit_mode == EditMode.MOVABLE and was_constructed:
		if event is InputEventMouseMotion:
			_update_from_target_pos()
