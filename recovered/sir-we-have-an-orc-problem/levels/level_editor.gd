@tool
class_name LevelEditor
extends Node2D

@export var map_texture: Texture2D
@export var sprite_sheet_texture: Texture2D
@export var enemy_health_buff: float
@export var level_bonus_marks: int = 0
@export var marks_upon_survival: int = 0
@export var marks_upon_all_killed: int = 0

@export_tool_button("Preview WorldData") var preview_world_data: = _on_preview_world_data
@export_tool_button("Save to LevelData") var save: = _on_save
@export_tool_button("Preview health values") var preview_halth_values_btn: = _on_preview_health_values

var sdf_texture: Texture2D
var flow_texture: Texture2D

func _on_preview_world_data() -> void :
	var world_data: = await WorldGen.create_world_data(map_texture)
	assert (world_data.successful)
	if !world_data.successful:
		return


	var img: = sprite_sheet_texture.get_image()
	const TILE_SIZE: = Vector2i(16, 16)
	@warning_ignore("integer_division")
	const TILE_CENTER: = TILE_SIZE / 2
	var wall_tiles_count: = 1
	wall_tiles_count += int(img.get_pixelv(TILE_CENTER + TILE_SIZE * Vector2i(0, 3)).a > 0.5)
	wall_tiles_count += int(img.get_pixelv(TILE_CENTER + TILE_SIZE * Vector2i(1, 3)).a > 0.5)
	wall_tiles_count += int(img.get_pixelv(TILE_CENTER + TILE_SIZE * Vector2i(2, 3)).a > 0.5)
	var ground_tiles_count: = 1
	ground_tiles_count += int(img.get_pixelv(TILE_CENTER + TILE_SIZE * Vector2i(3, 2)).a > 0.5)
	ground_tiles_count += int(img.get_pixelv(TILE_CENTER + TILE_SIZE * Vector2i(3, 1)).a > 0.5)
	ground_tiles_count += int(img.get_pixelv(TILE_CENTER + TILE_SIZE * Vector2i(3, 0)).a > 0.5)

	sdf_texture = world_data.sdf_tex
	%WorldSprite.texture = sdf_texture
	var world_shader_mat: = ( %WorldSprite.material as ShaderMaterial)
	world_shader_mat.set_shader_parameter("sdf_scale", float(WorldGen.WORLD_UNITS_PER_PIXEL))
	world_shader_mat.set_shader_parameter("world_size", Vector2(world_data.world_size))
	world_shader_mat.set_shader_parameter("tex_scale", Vector2(world_data.world_size) / 128.0)
	world_shader_mat.set_shader_parameter("wall_tiles_count", wall_tiles_count)
	world_shader_mat.set_shader_parameter("ground_tiles_count", ground_tiles_count)
	world_shader_mat.set_shader_parameter("sprite_sheet_tex", sprite_sheet_texture)
	world_shader_mat.set_shader_parameter("sdf_nearest", sdf_texture)
	world_shader_mat.set_shader_parameter("sdf_linear", sdf_texture)
	world_shader_mat.set_shader_parameter("flow_tex", flow_texture)
	%WorldSprite.scale = Vector2(WorldGen.WORLD_UNITS_PER_PIXEL, WorldGen.WORLD_UNITS_PER_PIXEL)

	flow_texture = world_data.flow_tex
	%FlowPreviewSprite.texture = flow_texture
	%FlowPreviewSprite.scale = Vector2(WorldGen.WORLD_UNITS_PER_PIXEL, WorldGen.WORLD_UNITS_PER_PIXEL)
	%FlowPreviewSprite.set_instance_shader_parameter("world_size", Vector2(world_data.world_size))

	for c: Node in %WorldCollision.get_children():
		c.queue_free()

	for p: CollisionPolygon2D in world_data.wall_polygons:
		var area: = Area2D.new()
		area.add_child(p)
		%WorldCollision.add_child(area)

func _get_property_list() -> Array[Dictionary]:
	return [
		{
			"name": "sdf_texture", 
			"type": TYPE_OBJECT, 
			"usage": PROPERTY_USAGE_EDITOR
		}, 
		{
			"name": "flow_texture", 
			"type": TYPE_OBJECT, 
			"usage": PROPERTY_USAGE_EDITOR
		}
	]

func _notification(what: int) -> void :
	if what == NOTIFICATION_EDITOR_PRE_SAVE:
		%WorldSprite.texture = null
		%FlowPreviewSprite.texture = null
		( %WorldSprite.material as ShaderMaterial).set_shader_parameter("sdf_nearest", null)
		( %WorldSprite.material as ShaderMaterial).set_shader_parameter("sdf_linear", null)
		( %WorldSprite.material as ShaderMaterial).set_shader_parameter("flow_tex", null)

	elif what == NOTIFICATION_EDITOR_POST_SAVE:
		%WorldSprite.texture = sdf_texture
		%FlowPreviewSprite.texture = flow_texture
		( %WorldSprite.material as ShaderMaterial).set_shader_parameter("sdf_nearest", sdf_texture)
		( %WorldSprite.material as ShaderMaterial).set_shader_parameter("sdf_linear", sdf_texture)
		( %WorldSprite.material as ShaderMaterial).set_shader_parameter("flow_tex", flow_texture)
		_on_save()

func _on_save() -> void :
	if !map_texture:
		push_error("map_texture missing")
		return
	var config: = ConfigFile.new()
	var config_err: = config.load(map_texture.resource_path + ".import")
	if config_err != OK:
		push_error("Couldn't load config of %s" % map_texture.resource_path)
	if config_err == OK:
		var fix_alpha_border: bool = config.get_value("params", "process/fix_alpha_border")
		if fix_alpha_border:
			push_error("'fix_alpha_border' is enabled in the import settings of the map_texture")
			return

	var target_level: = LevelData.new()
	target_level.map_texture = map_texture
	target_level.world_size = map_texture.get_size() * WorldGen.WORLD_UNITS_PER_PIXEL

	target_level.spawners = []
	for child: Node in %EnemySpawners.get_children():
		assert (child is EnemySpawnerEditor)
		var spawner: = child as EnemySpawnerEditor
		var spawner_data: = EnemySpawnerData.new()
		spawner_data.position = spawner.global_position
		spawner_data.shape = spawner.shape
		spawner_data.initial_velocity = spawner.initial_velocity
		spawner_data.waves = spawner.waves.duplicate()
		target_level.spawners.append(spawner_data)

	target_level.sprite_sheet_texture = sprite_sheet_texture
	var img: = sprite_sheet_texture.get_image()
	const TILE_SIZE: = Vector2i(16, 16)
	@warning_ignore("integer_division")
	const TILE_CENTER: = TILE_SIZE / 2
	target_level.wall_tiles_count = 1
	target_level.wall_tiles_count += int(img.get_pixelv(TILE_CENTER + TILE_SIZE * Vector2i(0, 3)).a > 0.5)
	target_level.wall_tiles_count += int(img.get_pixelv(TILE_CENTER + TILE_SIZE * Vector2i(1, 3)).a > 0.5)
	target_level.wall_tiles_count += int(img.get_pixelv(TILE_CENTER + TILE_SIZE * Vector2i(2, 3)).a > 0.5)
	target_level.ground_tiles_count = 1
	target_level.ground_tiles_count += int(img.get_pixelv(TILE_CENTER + TILE_SIZE * Vector2i(3, 2)).a > 0.5)
	target_level.ground_tiles_count += int(img.get_pixelv(TILE_CENTER + TILE_SIZE * Vector2i(3, 1)).a > 0.5)
	target_level.ground_tiles_count += int(img.get_pixelv(TILE_CENTER + TILE_SIZE * Vector2i(3, 0)).a > 0.5)
	target_level.enemy_health_buff = enemy_health_buff
	target_level.level_bonus_marks = level_bonus_marks
	target_level.marks_upon_survival = marks_upon_survival
	target_level.marks_upon_all_killed = marks_upon_all_killed

	target_level.emit_changed()
	var file_path: String = map_texture.resource_path.get_basename() + ".tres"
	var save_err: = ResourceSaver.save(target_level, file_path)
	if save_err == OK:
		print("Saved level %s" % file_path)
	else:
		print("Error while saving level '%s': %d" % save_err)

func _on_preview_health_values() -> void :
	var total_enemy_count: = 0
	var total_time: = 0.0
	for child: Node in %EnemySpawners.get_children():
		assert (child is EnemySpawnerEditor)
		var spawner: = child as EnemySpawnerEditor
		var total_spawner_time: = 0.0
		for wave: EnemySpawnWave in spawner.waves:
			total_enemy_count += wave.amount
			total_spawner_time += wave.duration
		total_time = max(total_time, total_spawner_time)

	var avg_radius_factor: = 0.1
	var avg_radius: = GameManager.ENEMY_MIN_RADIUS + (GameManager.ENEMY_MAX_RADIUS - GameManager.ENEMY_MIN_RADIUS) * avg_radius_factor
	var avg_relative_time: = 1.5
	var radius_f: = (avg_radius * avg_radius) * GameManager.ENEMY_HEALTH_BUFF_RADIUS
	var time_f: = (1.0 + avg_relative_time * GameManager.ENEMY_HEALTH_BUFF_OVER_TIME)
	var level_f: = enemy_health_buff
	var avg_health: = radius_f * time_f * level_f

	print("Total enemies: %d" % total_enemy_count)
	print("Total spawn time: %.0fs" % total_time)
	print("Enemies spawning per second: %.0f" % (total_enemy_count / total_time))
	print("Average health: %.1f" % avg_health)
	print("Total health: %.0f" % (total_enemy_count * avg_health))
