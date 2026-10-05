class_name LevelPanel
extends PanelContainer

var level_id: = 0
var is_unlocked: = false

func _ready() -> void :
	var level: GameManager.Level = GameManager.levels.get(level_id, null)
	assert (level, "What's going on?")

	is_unlocked = level_id == 1
	if level_id > 1:
		var level_before: GameManager.Level = GameManager.levels.get(level_id - 1, null)
		is_unlocked = level_before.has_survived

	%LevelNameLabel.text = level.name
	%MapTextureRect.texture = level.data.map_texture
	( %MapTextureRect.material as ShaderMaterial).set_shader_parameter("tilemap", level.data.sprite_sheet_texture)
	%LockTextureRect.visible = !is_unlocked
	%LevelFinishedTextureRect.modulate.a = 0.1 if level.has_survived else 1.0
	%AllKilledTextureRect.modulate.a = 0.1 if level.has_killed_all else 1.0

	%DebugUnlockButton.visible = DevOptions.cheats_enabled and !is_unlocked
	%AmountHBox.visible = is_unlocked
	%AmountOrcsLabel.text = NumberFormatter.format(get_total_enemies_to_spawn(level.data))
	%HPHBox.visible = is_unlocked

	var health_range_min: = GameManager.get_enemy_health(GameManager.ENEMY_MIN_RADIUS, 0.0, level)
	var health_range_max: = GameManager.get_enemy_health(GameManager.ENEMY_MAX_RADIUS, 1.0, level)
	%HealthRangeLabel.text = "%.1f - %.1f" % [health_range_min, health_range_max]

	var grants_marks_upon_survival: = level.data.marks_upon_survival > 0
	%LevelFinishedTextureRect.visible = !grants_marks_upon_survival
	%SurvivedMarksContainer.visible = grants_marks_upon_survival
	%SurvivedMarksLabel.text = NumberFormatter.format(level.data.marks_upon_survival)
	%SurvivedMarksContainer.modulate.a = 0.1 if level.has_survived else 1.0

	var grants_marks_upon_all_killed: = level.data.marks_upon_all_killed > 0
	%AllKilledTextureRect.visible = !grants_marks_upon_all_killed
	%AllKilledMarksContainer.visible = grants_marks_upon_all_killed
	%AllKilledMarksLabel.text = NumberFormatter.format(level.data.marks_upon_all_killed)
	%AllKilledMarksContainer.modulate.a = 0.1 if level.has_killed_all else 1.0

	var stats_tooltip: String = ""
	stats_tooltip += "%s %d\n" % [tr("Attempts:"), level.stats.times_started]
	stats_tooltip += "%s %d\n" % [tr("Survivals:"), level.stats.times_survived]
	stats_tooltip += "%s %d\n" % [tr("All orcs killed:"), level.stats.times_all_killed]
	stats_tooltip += "%s %s\n" % [tr("First attempt:"), make_time_string(level.stats.first_time_started)]
	stats_tooltip += "%s %s\n" % [tr("First survival:"), make_time_string(level.stats.first_time_survived)]
	stats_tooltip += "%s %s\n" % [tr("First all orcs killed:"), make_time_string(level.stats.first_time_all_killed)]
	stats_tooltip += "%s %s\n" % [tr("Total earned:"), NumberFormatter.format(level.stats.total_marks_earned)]

	%InfoTextureRect.tooltip_text = stats_tooltip

func _on_mouse_entered() -> void :
	self_modulate = Color.WHITE * (2.0 if is_unlocked else 1.2)
	scale = Vector2.ONE * 1.05

func _on_mouse_exited() -> void :
	self_modulate = Color.WHITE
	scale = Vector2.ONE

func _on_gui_input(event: InputEvent) -> void :
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_released():
			if is_unlocked:
				AudioManager.play_ui_sound(AudioManager.ui_click, 0.0, randf_range(0.9, 1.1))
				GameManager.load_level(level_id)
				SaveSystem.save_user_data()
			else:
				AudioManager.play_ui_sound(AudioManager.ui_wrong, 0.0, randf_range(0.9, 1.1))

func _on_debug_unlock_button_pressed() -> void :
	is_unlocked = true
	%DebugUnlockButton.visible = false
	%LockTextureRect.visible = !is_unlocked
	%AmountHBox.visible = is_unlocked
	%HPHBox.visible = is_unlocked

func get_total_enemies_to_spawn(level_data: LevelData) -> int:
	var result: = 0
	for spawner_data: EnemySpawnerData in level_data.spawners:
		result += spawner_data.waves.reduce(
			func(accum: int, wave: EnemySpawnWave) -> int: return accum + wave.amount
			, 0
		)
	return result

@warning_ignore_start("integer_division")
func make_time_string(time_seconds: int) -> String:
	var hours: = time_seconds / 3600
	var minutes: = (time_seconds % 3600) / 60
	var seconds: = time_seconds % 60
	return "%02d:%02d:%02d" % [hours, minutes, seconds]
@warning_ignore_restore("integer_division")
