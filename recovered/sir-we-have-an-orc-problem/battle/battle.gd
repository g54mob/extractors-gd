class_name Battle
extends Node2D

@export var corpse_tex: Texture2D
@export var fire_tex: Texture2D
@export var flame_scale_curve_tex: CurveTexture
@export var supporter_sprite_sheet_tex: Texture2D

enum Phase{
	BUILD, 
	BATTLE, 
	END, 
}

signal enemies_spawned(count: int)
signal enemies_killed(count: int)
signal enemies_arrived_at_base(count: int)
signal enemies_alive_updated(new_count: int)
signal health_changed(new_amount: float)
signal paused_changed(paused: bool)
signal ended(health_remaining: float, surrendered: bool)
signal phase_changed(new_phase: Phase)

const BASE_MAX_HEALTH: int = 50

var total_enemies_to_spawn: int = 0
var total_enemies_spawned: int = 0
var total_enemies_killed: int = 0
var total_enemies_at_base: int = 0
var total_enemies_alive: int = 0
var total_golden_enemies_killed: int = 0

var phase: Phase = Phase.BUILD:
	set(value):
		if value == phase:
			return
		assert (value > phase, "Phases can only progress forwards")
		phase = value

		GameManager.should_count_battle_time = (phase == Phase.BATTLE)
		phase_changed.emit(phase)

signal tower_added(tower: BaseTower)
signal tower_removed(tower: BaseTower)

func add_tower(tower: BaseTower) -> void :
	tower_added.emit(tower)

func remove_tower(tower: BaseTower) -> void :
	tower_removed.emit(tower)

func _end_battle(surrendered: bool = false) -> void :
	if DevOptions.skip_end_of_battle:
		return

	if phase == Phase.END:
		return
	phase = Phase.END
	ended.emit(health, surrendered)

var health: float:
	set(value):
		health = value
		health_changed.emit(health)
		if health <= 0.0:
			_end_battle()

static func get_max_health() -> float:
	return (BASE_MAX_HEALTH
		+ TechTree.get_upgrade(&"base_hp").current_value
		+ TechTree.get_upgrade(&"base_hp_2").current_value)

var world_data: WorldGen.WorldData


const AUDIO_PLAYER_OFFSETS: Array[Vector2] = [
	Vector2(0.0, 0.0), 
	Vector2(-1.0, -1.0), 
	Vector2(1.0, -1.0), 
	Vector2(-1.0, 1.0), 
	Vector2(1.0, 1.0), 
]

class AudioPlayerGroup:
	var root_node: Node2D
	var property_name: StringName
	var volume_factor_max: float
	var volume_factor: float = 1.0
	var last_volume: float
	func _init(root_node_in: Node2D, property_name_in: StringName, volume_in: float, volume_factor_in: float = 1.0) -> void :
		root_node = root_node_in
		property_name = property_name_in
		volume_factor_max = volume_in
		volume_factor = volume_factor_in


@onready var audio_player_groups: Array[AudioPlayerGroup] = [
	AudioPlayerGroup.new( %AudioRunning, &"enemies_alive", 128.0, 0.1), 
]

func property_to_volume(value: float, max_value: float) -> float:
	return clamp(log(max(value, 1.0)) / log(max_value), 0.0, 1.0)

var world_shader_mat: ShaderMaterial
var level: GameManager.Level

func _ready() -> void :
	%DebugContainer.visible = DevOptions.cheats_enabled
	BaseTower.towers_built.clear()
	var level_id: int = GameManager.selected_level
	assert (GameManager.levels.has(level_id))
	level = GameManager.levels[level_id]
	for tower_data: Dictionary in level.towers:
		var tower: = BaseTower.create_from_data(tower_data)
		if tower:
			tower.was_constructed = true
			%TowerPlacement.add_child(tower)
			tower.has_valid_placement = true
			tower.construct()

	GPUSim.enemies_killed.connect(_on_enemies_killed)
	GPUSim.base_damage_received.connect(_on_base_damage_received)
	GPUSim.enemies_alive_updated.connect( func(new_count: int) -> void :
		total_enemies_alive = new_count
		enemies_alive_updated.emit(total_enemies_alive)
		check_for_survival()
		)
	GPUSim.readback_grid_updated.connect( func(grid: GPUSim.ReadbackGridCPU) -> void :
		var sample_level: float = remap(log( %Camera2D.zoom.y), log(1.0), log(10.0), float(grid.levels.size() - 1), 0.0)
		var sample_level_volume: float = 1.0 - ((sample_level) / float(grid.levels.size()))
		var corner_distance: float = 500.0

		for audio_group: AudioPlayerGroup in audio_player_groups:
			for i: int in audio_group.root_node.get_child_count():
				var offset: Vector2 = AUDIO_PLAYER_OFFSETS[i] * corner_distance
				var sample_pos: Vector2 = %Camera2D.global_position + offset / %Camera2D.zoom
				var audio_player: AudioStreamPlayer2D = audio_group.root_node.get_child(i)
				audio_player.position = offset / %Camera2D.zoom
				var value: float = grid.sample_bilinear_mipmap(audio_group.property_name, sample_pos, sample_level)
				var max_value: float = audio_group.volume_factor_max * pow(2.0, sample_level)
				var new_volume: = property_to_volume(value, max_value) * audio_group.volume_factor
				audio_group.last_volume = lerpf(audio_group.last_volume, new_volume, 0.2)
				audio_player.volume_linear = audio_group.last_volume * sample_level_volume


	)
	var level_data: LevelData = level.data

	world_data = await WorldGen.create_world_data(level_data.map_texture)
	assert (world_data.successful)
	if !world_data.successful:
		return

	var world_corpses_tex: = Texture2DRD.new()
	var world_fire_tex: = Texture2DRD.new()
	GPUSim.set_world_data(world_data, world_corpses_tex, corpse_tex, world_fire_tex, fire_tex, flame_scale_curve_tex)
	%RigidbodiesDebugTextureRect.initialize()
	%TransparentTextureRect.initialize()

	%WorldSprite.texture = world_data.sdf_tex
	%WorldSprite.scale = Vector2.ONE * WorldGen.WORLD_UNITS_PER_PIXEL
	world_shader_mat = ( %WorldSprite.material as ShaderMaterial)
	world_shader_mat.set_shader_parameter("sdf_scale", float(WorldGen.WORLD_UNITS_PER_PIXEL))
	world_shader_mat.set_shader_parameter("world_size", Vector2(world_data.world_size))

	if Options.supporter_background_enabled:
		world_shader_mat.set_shader_parameter("wall_tiles_count", 1)
		world_shader_mat.set_shader_parameter("ground_tiles_count", 1)
		world_shader_mat.set_shader_parameter("sprite_sheet_tex", supporter_sprite_sheet_tex)
	else:
		world_shader_mat.set_shader_parameter("wall_tiles_count", level_data.wall_tiles_count)
		world_shader_mat.set_shader_parameter("ground_tiles_count", level_data.ground_tiles_count)
		world_shader_mat.set_shader_parameter("sprite_sheet_tex", level_data.sprite_sheet_texture)

	var fire_color: = Vector3(0.1, 1.0, 4.0) if Options.supporter_flames_enabled else Vector3(3.5, 2.0, 0.1)
	world_shader_mat.set_shader_parameter("fire_color", fire_color)

	world_shader_mat.set_shader_parameter("sdf_nearest", world_data.sdf_tex)
	world_shader_mat.set_shader_parameter("sdf_linear", world_data.sdf_tex)
	world_shader_mat.set_shader_parameter("flow_tex", world_data.flow_tex)
	world_shader_mat.set_shader_parameter("corpses_tex", world_corpses_tex)
	world_shader_mat.set_shader_parameter("fire_tex", world_fire_tex)

	for p: CollisionPolygon2D in world_data.wall_polygons:
		var area: = Area2D.new()
		area.collision_layer = 1 << 4
		area.monitoring = false
		area.disable_mode = CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE
		area.add_child(p)
		%WorldCollision.add_child(area)

	assert (level_data.spawners.size() > 0)
	for spawner_data: EnemySpawnerData in level_data.spawners:
		var spawner: EnemySpawner = load("res://battle/enemy_spawner.tscn").instantiate()
		spawner.battle = self
		spawner.position = spawner_data.position
		spawner.spawner_data = spawner_data
		total_enemies_to_spawn += spawner_data.waves.reduce(
			func(accum: int, wave: EnemySpawnWave) -> int: return accum + wave.amount
			, 0
		)
		spawner.enemies_spawned.connect(_on_enemies_spawned)
		%EnemySpawners.add_child(spawner)

	health = get_max_health()

	set_pause(true)

	GPUSim.flow_speed = 45.0 + level_id * 5.0
	GPUSim.start()

	%Camera2D.zoom = Vector2.ONE * min(get_viewport_rect().size.x / world_data.world_size.x, get_viewport_rect().size.y / world_data.world_size.y)
	%Camera2D.target_zoom = %Camera2D.zoom
	%Camera2D.position = world_data.world_size * 0.5
	%Camera2D.limits = Vector4(0, 0, world_data.world_size.x, world_data.world_size.y)

	AudioManager.camera = %Camera2D

	TutorialManager.show_battle_tutorial()

func _process(_delta: float) -> void :
	world_shader_mat.set_shader_parameter("sim_time", GPUSim.simulation_time)

func _exit_tree() -> void :
	Engine.time_scale = 1.0

func _on_enemies_killed(count: int, data: PackedByteArray) -> void :
	total_enemies_killed += count
	enemies_killed.emit(count)
	@warning_ignore("integer_division")
	var readable: int = min(count, data.size() / 16)
	var golden_count: int = 0
	for i: int in readable:
		var pos: Vector2
		pos.x = data.decode_float(4 * (i * 4 + 0))
		pos.y = data.decode_float(4 * (i * 4 + 1))
		var sim_meta: int = data.decode_u32(4 * (i * 4 + 2))
		var flags: int = (sim_meta >> (1 * 8)) & 255
		if (flags & Rigidbody.Flags.EXPLODE_ON_DEATH) != 0:
			AudioManager.play_sound_at(Constants.explosion_sound, pos, 0.0, randf_range(0.9, 1.1))
		if (flags & Rigidbody.Flags.IS_GOLDEN) != 0:
			golden_count += 1
	total_golden_enemies_killed += golden_count

func check_for_survival() -> void :
	if health > 0.0 and total_enemies_alive == 0 and total_enemies_spawned == total_enemies_to_spawn:
		_end_battle()

func _on_enemies_spawned(count: int) -> void :
	total_enemies_spawned += count
	enemies_spawned.emit(count)

func _on_base_damage_received(damage: float) -> void :
	health -= damage

	var count: int = int(damage)
	total_enemies_at_base += count
	enemies_arrived_at_base.emit(count)

var is_paused: bool = true:
	set(value):
		is_paused = value
		paused_changed.emit(is_paused)

var is_pausable: bool = true
func set_pause(paused: bool) -> void :
	if !is_pausable:
		return
	get_tree().paused = paused
	PhysicsServer2D.set_active(true)
	is_paused = paused
	%PauseContainer.visible = is_paused and phase == Phase.BATTLE
	%BuildPhaseContainer.visible = is_paused and phase == Phase.BUILD
	GameManager.should_count_battle_time = (phase == Phase.BATTLE && !is_paused)
	if !is_paused and phase == Phase.BUILD:
		phase = Phase.BATTLE

func set_pausable(pausable: bool) -> void :
	is_pausable = pausable

func toggle_pause() -> void :
	if !is_pausable:
		return
	set_pause( !is_paused)

func write_towers_to_level_progress() -> void :
	level.towers.clear()
	for node: Node in %TowerPlacement.get_children():
		var tower: = node as BaseTower
		if tower and tower.has_valid_placement:
			level.towers.append(tower.save_to_data())

func unselect_all_towers() -> void :
	for node: Node in %TowerPlacement.get_children():
		var tower: = node as BaseTower
		if tower and tower.was_constructed:
			tower.edit_mode = BaseTower.EditMode.NORMAL

func _on_game_speed_slider_gui_input(event: InputEvent) -> void :
	if event is InputEventMouseButton:
		var mbtn: InputEventMouseButton = event
		if mbtn.button_index == MOUSE_BUTTON_RIGHT and mbtn.pressed:
			%GameSpeedSlider.value = 1.0

func get_tower_types_count() -> int:
	var types: Dictionary = {}
	for node: Node in %TowerPlacement.get_children():
		var tower: = node as BaseTower
		if tower and tower.has_valid_placement:
			@warning_ignore("static_called_on_instance")
			types[tower.get_kind()] = 1

	return types.size()
