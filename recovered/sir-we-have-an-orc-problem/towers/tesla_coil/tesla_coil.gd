class_name TeslaCoil
extends BaseTower

@onready var audio_player: AudioStreamPlayer2D = $AudioPlayer

const BASE_DAMAGE: float = 2.0
const BASE_FIRE_RATE: float = 0.75
const BASE_CHAINING: int = 2
const BASE_RANGE: float = 35.0
const BASE_SHOCK_DURATION: float = 0.0

var damage: float = BASE_DAMAGE
var fire_rate: float = BASE_FIRE_RATE
var fire_range: float = BASE_RANGE
var chaining: int = BASE_CHAINING
var delta_overflow: float = 0.0

static func get_damage() -> float:
	return (BASE_DAMAGE
		+ TechTree.get_upgrade(&"tesla_coil_damage").current_value
		+ TechTree.get_upgrade(&"tesla_coil_damage_2").current_value
		+ TechTree.get_upgrade(&"tesla_coil_damage_3").current_value
	)

static func get_firerate() -> float:
	return (BASE_FIRE_RATE
		+ TechTree.get_upgrade(&"tesla_coil_firerate").current_value
		+ TechTree.get_upgrade(&"tesla_coil_firerate_2").current_value
	)

static func get_range() -> float:
	return (BASE_RANGE
		+ TechTree.get_upgrade(&"tesla_coil_range").current_value
	)

static func get_chaining() -> int:
	return roundi(BASE_CHAINING
		+ TechTree.get_upgrade(&"tesla_coil_chaining").current_value
		+ TechTree.get_upgrade(&"tesla_coil_chaining_2").current_value
	)


static func get_confusion_factor() -> float:
	return (TechTree.get_upgrade(&"tesla_coil_confusion").current_value)

static func get_shock_duration() -> float:
	return (BASE_SHOCK_DURATION
		+ TechTree.get_upgrade(&"tesla_coil_confusion").current_value
		+ TechTree.get_upgrade(&"tesla_coil_shock_duration").current_value)

var target_preview_points: = PackedVector2Array()

func _ready() -> void :
	super._ready()
	damage = get_damage()
	fire_rate = get_firerate()
	fire_range = get_range()
	chaining = get_chaining()

	delta_overflow = randf_range(0.0, 1.0 / fire_rate) * 0.5

	target_preview_points.resize(32)
	var angle_step: float = 2.0 * PI / target_preview_points.size()
	var base_target_preview_scale: = (Vector2.ONE / scale)
	for i: int in target_preview_points.size():
		target_preview_points[i] = Vector2.from_angle(angle_step * i) * base_target_preview_scale * fire_range
	%TargetPreview.points = target_preview_points

	on_edit_mode_changed()
	battle.phase_changed.connect(_on_battle_phase_changed)

func on_edit_mode_changed() -> void :
	super.on_edit_mode_changed()
	%TargetPreview.modulate.a = 1.0 if edit_mode == EditMode.EDIT_TARGET else 0.2
	%TargetPreview.visible = battle.phase == Battle.Phase.BUILD

func _on_battle_phase_changed(_new_phase: Battle.Phase) -> void :
	%TargetPreview.visible = battle.phase == Battle.Phase.BUILD


static func get_kind() -> TowerKind:
	return TowerKind.TESLA_COIL

static func is_unlocked() -> bool:
	return is_tower_unlocked(get_kind())

static func get_tower_limit(_tower_kind: BaseTower.TowerKind) -> int:
	return int(1
		+ TechTree.get_upgrade(&"tesla_coil_count").current_value
		+ TechTree.get_upgrade(&"tesla_coil_count_2").current_value
		+ TechTree.get_upgrade(&"tesla_coil_count_3").current_value
	)

static func get_icon(_tower_kind: BaseTower.TowerKind) -> Texture2D:
	return load("res://towers/tesla_coil/tesla_coil_icon.png")

static func _create_from_data(data: Dictionary) -> BaseTower:
	var tesla_coil: TeslaCoil = load(BaseTower.TOWER_SCENES[get_kind()]).instantiate()
	tesla_coil.global_position = Vector2(data["position"]["x"], data["position"]["y"])
	return tesla_coil

func save_to_data() -> Dictionary:
	return {
		"kind": TowerKind.keys()[get_kind()], 
		"position": {"x": global_position.x, "y": global_position.y}, 
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


	var damage_area: = Rigidbody.new(global_position, Vector2.ZERO, fire_range, 1.0, 0.0)
	damage_area.layer = Rigidbody.Layers.EFFECTS
	damage_area.sensor_mask = Rigidbody.Layers.ENEMIES
	damage_area.ch_damage_other = damage
	damage_area.ch_chaining = chaining
	damage_area.ch_flags = Rigidbody.ContactHandlerFlags.CLOSEST_ONLY
	damage_area.ch_damage_report_id = Constants.DAMAGE_REPORT_ID_TESLA_COIL
	GPUSim.add_rigidbodies([damage_area])

	%ActiveSprite.modulate.a = 1.0
	var tween: = create_tween()
	tween.tween_property( %ActiveSprite, "modulate:a", 0.0, min(0.2, (1.0 / fire_rate))).set_ease(Tween.EASE_IN)

	audio_player.pitch_scale = randf_range(0.9, 1.1)
	audio_player.play()

func _unhandled_input(event: InputEvent) -> void :
	super._unhandled_input(event)
