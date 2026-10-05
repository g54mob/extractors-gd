extends CanvasLayer

@onready var debug_label: Label = %DebugLabel


class DamagePreset:
	var damage_category: DamageCategory
	var damage_report_id: int
	func _init(icon: Texture2D, id_in: int, tooltip: String) -> void :
		damage_category = load("res://battle/hud/damage_category.tscn").instantiate()
		damage_category.tooltip = tooltip
		damage_category.icon = icon
		damage_report_id = id_in

var damage_presets: Array[DamagePreset] = []
var nuke_dmg_before: float = 0

var battle: Battle
func _ready() -> void :
	battle = get_tree().get_first_node_in_group("battle")
	battle.ended.connect(_on_battle_ended, CONNECT_ONE_SHOT)
	battle.phase_changed.connect(_on_battle_phase_changed)
	%GameSpeedSlider.value = 1.0
	show_controls_container()

	if Gunner.is_unlocked():
		damage_presets.append(DamagePreset.new(load("res://towers/gunner/gunner_icon.png"), Constants.DAMAGE_REPORT_ID_GUNNER, "Gunner"))
	if Cannon.is_unlocked():
		damage_presets.append(DamagePreset.new(load("res://towers/cannon/cannon_icon.png"), Constants.DAMAGE_REPORT_ID_CANNON, "Cannon"))
	if Mortar.is_unlocked():
		damage_presets.append(DamagePreset.new(load("res://towers/mortar/mortar_icon.png"), Constants.DAMAGE_REPORT_ID_MORTAR, "Mortar"))
	if Flamethrower.is_unlocked():
		damage_presets.append(DamagePreset.new(load("res://towers/flamethrower/flamethrower_icon.png"), Constants.DAMAGE_REPORT_ID_FLAMETHROWER, "Flamethrower"))
	if TeslaCoil.is_unlocked():
		damage_presets.append(DamagePreset.new(load("res://towers/tesla_coil/tesla_coil_icon.png"), Constants.DAMAGE_REPORT_ID_TESLA_COIL, "Tesla Coil"))
	if GrenadeLauncher.is_unlocked():
		damage_presets.append(DamagePreset.new(load("res://towers/grenade_launcher/grenade_launcher_icon.png"), Constants.DAMAGE_REPORT_ID_GRENADE_LAUNCHER, "Grenade Launcher"))
	if Laser.is_unlocked():
		damage_presets.append(DamagePreset.new(load("res://towers/laser/laser_icon.png"), Constants.DAMAGE_REPORT_ID_LASER, "Laser"))


	if Missile.is_unlocked():
		damage_presets.append(DamagePreset.new(load("res://abilities/missile/missile_icon.png"), Constants.DAMAGE_REPORT_ID_MISSILE, "Missile"))
	if StrafingRun.is_unlocked():
		damage_presets.append(DamagePreset.new(load("res://abilities/strafing_run/strafing_run_icon.png"), Constants.DAMAGE_REPORT_ID_STRAFING_RUN, "Strafing Run"))
	if Nuke.is_unlocked():
		damage_presets.append(DamagePreset.new(load("res://abilities/nuke/nuke_icon.png"), Constants.DAMAGE_REPORT_ID_NUKE, "Nuke"))
	if CryoBeam.is_unlocked():
		damage_presets.append(DamagePreset.new(load("res://abilities/cryo_beam/cryo_beam_icon.png"), Constants.DAMAGE_REPORT_ID_CRYO_BEAM, "Orbital Cryo Beam"))

	if TechTree.get_upgrade(&"explosive_orcs_unlock").current_value > 0.0:
		damage_presets.append(DamagePreset.new(load("res://enemies/explosive_orcs_icon.png"), Constants.DAMAGE_REPORT_ID_EXPLODING_ORCS, "Explosive Orcs"))

	for i: int in damage_presets.size():
		%DamageList.add_child(damage_presets[i].damage_category)
	GPUSim.contact_handlers_damage_updated.connect( func() -> void :
		var highest_damage: float = 0.0
		for preset: DamagePreset in damage_presets:
			var damage: float = GPUSim.contact_handlers_damage[preset.damage_report_id]
			highest_damage = max(highest_damage, damage)
		for preset: DamagePreset in damage_presets:
			var damage: float = GPUSim.contact_handlers_damage[preset.damage_report_id]
			preset.damage_category.damage_label.text = NumberFormatter.format(roundi(damage))
			preset.damage_category.progress_bar.value = (damage / highest_damage) if highest_damage > 0.0 else 0.0

		var nuke_dmg: float = GPUSim.contact_handlers_damage[Constants.DAMAGE_REPORT_ID_NUKE]
		var difference: float = nuke_dmg - nuke_dmg_before
		if difference >= 666000.0:
			Achievements.set_achieved(Achievements.NUKE)
		nuke_dmg_before = nuke_dmg
	)

	%DamageList.visible = TechTree.get_upgrade(&"dmg_stats").level > 0

	EventBus.last_use_shot.connect(_on_ability_button_toggled.bind(true, 1))

	%HideResultsButton.visible = false

func _process(_delta: float) -> void :
	var debug_text: String = ""
	debug_text += "%.1f FPS\n" % Engine.get_frames_per_second()
	debug_text += "%.2fms GPU sim\n" % GPUSim.gpu_time_ms
	debug_text += "%.2fms GPU max\n" % GPUSim.gpu_time_ms_history.max()
	debug_text += "%d Bodies: +%d | -%d\n" % [GPUSim.body_count, GPUSim.addition_count, GPUSim.removal_count]
	debug_text += "%d Enemies\n%d Projectiles\n%d Explosions\n%d Effects\n %d Flames\n" % [
		GPUSim.enemy_count, 
		GPUSim.projectile_count, 
		GPUSim.explosion_count, 
		GPUSim.effect_count, 
		GPUSim.flame_count]
	debug_text += "%d Contacts\n" % GPUSim.contact_count
	debug_label.text = debug_text

func _on_battle_phase_changed(new_phase: Battle.Phase) -> void :
	%TowerContainer.visible = new_phase == Battle.Phase.BUILD
	%AbilityContainer.visible = new_phase == Battle.Phase.BATTLE

func _on_tech_tree_button_pressed() -> void :
	GPUSim.stop()
	Engine.time_scale = 1.0
	SceneTransition.change_scene(Constants.TECH_TREE_SCENE_PATH)

func _on_render_interpolation_button_toggled(toggled_on: bool) -> void :
	GPUSim.USE_RENDER_POSITION_INTERPOLATION = toggled_on

func _on_skip_end_of_battle_button_tree_entered() -> void :
	%SkipEndOfBattleButton.button_pressed = DevOptions.skip_end_of_battle

func _on_skip_end_of_battle_button_toggled(toggled_on: bool) -> void :
	DevOptions.skip_end_of_battle = toggled_on

func _on_game_speed_slider_value_changed(value: float) -> void :
	Engine.time_scale = value

@onready var battle_end_container: PanelContainer = %BattleEndContainer
@onready var battle_end_title_label: Label = %BattleEndTitleLabel
@onready var upgrade_marks_count_label: Label = %UpgradeMarksCountLabel

func show_battle_end_screen(survived: bool, earn_level_finished: bool = false, earn_all_killed: bool = false, surrendered: bool = false) -> void :
	battle.write_towers_to_level_progress()
	battle.set_pause(true)
	battle.set_pausable(false)
	battle_end_title_label.text = tr("Survived") if survived else tr("Lost")

	%MarksForKillsCaption.text = tr("Kills ({x})").format({"x": NumberFormatter.format(battle.total_enemies_killed)})
	var upgrade_marks_earned: int = maxi(1, ceili(battle.total_enemies_killed / GameManager.get_kill_count_divisor()))
	%MarksForKillsCountLabel.text = NumberFormatter.format(upgrade_marks_earned)

	%MarksCollectedContainer.visible = TechTree.get_upgrade(&"golden_orcs").level > 0
	%MarksCollectedCaption.text = tr("Silver Orcs ({x})").format({"x": NumberFormatter.format(battle.total_golden_enemies_killed)})
	var golden_orc_marks: int = battle.total_golden_enemies_killed * EnemySpawner.get_golden_orc_money()
	%MarksCollectedCountLabel.text = NumberFormatter.format(golden_orc_marks)
	upgrade_marks_earned += golden_orc_marks

	%BonusMarksFlatContainer.visible = TechTree.get_upgrade(&"marks_bonus").level > 0
	if !surrendered:
		var bonus_marks_flat: int = roundi(TechTree.get_upgrade(&"marks_bonus").current_value)
		if GameManager.selected_level >= 5:
			bonus_marks_flat += roundi(TechTree.get_upgrade(&"marks_bonus_2").current_value)
		if GameManager.selected_level >= 7:
			bonus_marks_flat += roundi(TechTree.get_upgrade(&"marks_bonus_4").current_value)
		%BonusMarksFlatCountLabel.text = NumberFormatter.format(bonus_marks_flat)
		upgrade_marks_earned += bonus_marks_flat

	%BonusMarksPercentageContainer.visible = TechTree.get_upgrade(&"marks_percentage").level > 0
	%BonusMarksPercentageCaption.text = tr("Bonus ({x}%)").format({"x": TechTree.get_upgrade(&"marks_percentage").current_value})
	var marks_percentage_bonus: int = roundi(upgrade_marks_earned * (TechTree.get_upgrade(&"marks_percentage").current_value / 100))
	%BonusMarksPercentageCountLabel.text = NumberFormatter.format(marks_percentage_bonus)
	upgrade_marks_earned += marks_percentage_bonus

	var gain_level_bonus_marks: bool = battle.level.data.level_bonus_marks > 0 and !surrendered
	%LevelBonusContainer.visible = gain_level_bonus_marks
	if gain_level_bonus_marks:
		%LevelBonusCountLabel.text = NumberFormatter.format(battle.level.data.level_bonus_marks)
		upgrade_marks_earned += battle.level.data.level_bonus_marks

	var gain_survived_marks: bool = battle.level.data.marks_upon_survival > 0 and survived and earn_level_finished
	%SurvivedMarksContainer.visible = gain_survived_marks
	if gain_survived_marks:
		%SurvivedMarksCountLabel.text = NumberFormatter.format(battle.level.data.marks_upon_survival)
		upgrade_marks_earned += battle.level.data.marks_upon_survival

	var gain_all_killed_marks: bool = battle.level.data.marks_upon_all_killed > 0 and survived and earn_all_killed
	%AllKilledMarksContainer.visible = gain_all_killed_marks
	if gain_all_killed_marks:
		%AllKilledMarksCountLabel.text = NumberFormatter.format(battle.level.data.marks_upon_all_killed)
		upgrade_marks_earned += battle.level.data.marks_upon_all_killed

	battle.level.stats.total_marks_earned += upgrade_marks_earned
	GameManager.earn_currency(Currency.Type.UPGRADE_MARKS, upgrade_marks_earned)
	upgrade_marks_count_label.text = NumberFormatter.format(upgrade_marks_earned)

	earn_level_finished = earn_level_finished and battle.level.data.marks_upon_survival == 0
	%LevelFinishedContainer.visible = earn_level_finished
	if earn_level_finished:
		GameManager.earn_currency(Currency.Type.LEVEL_FINISHED, 1)

	earn_all_killed = earn_all_killed and battle.level.data.marks_upon_all_killed == 0
	%AllKilledContainer.visible = earn_all_killed
	if earn_all_killed:
		GameManager.earn_currency(Currency.Type.ALL_KILLED_CHALLENGE, 1)

	battle_end_container.visible = true
	%BattleEndRestartButton.visible = TutorialManager.has_finished_tutorial
	SaveSystem.save_save_data()

	%HideResultsButton.visible = true

	if survived and !surrendered:
		if GameManager.selected_level == 1:
			Achievements.set_achieved(Achievements.SURVIVE_1)
			if %TowerPlacement.get_child_count() == 1 and get_total_ability_damage() < 0.1:
				Achievements.set_achieved(Achievements.ONE_TOWER)
		elif GameManager.selected_level == 3:
			if %TowerPlacement.get_child_count() == 0:
				Achievements.set_achieved(Achievements.NO_TOWERS)
		elif GameManager.selected_level == 5:
			Achievements.set_achieved(Achievements.SURVIVE_3)
			if battle.get_tower_types_count() == 1 and get_total_ability_damage() < 0.1:
				Achievements.set_achieved(Achievements.ONE_TOWER_TYPE)
		elif GameManager.selected_level == 7 and check_elemental_carnage_achievement():
			Achievements.set_achieved(Achievements.ELEMENTAL)
		elif GameManager.selected_level == 9 and battle.get_tower_types_count() <= 3 and get_total_ability_damage() < 0.1:
			Achievements.set_achieved(Achievements.THREE_TOWER_TYPE)
		elif GameManager.selected_level == 11 and battle.get_tower_types_count() <= 4 and get_total_ability_damage() < 0.1:
			Achievements.set_achieved(Achievements.FOUR_TOWER_TYPE)
		elif GameManager.selected_level == 12:
			Achievements.set_achieved(Achievements.SURVIVE_6)


func _on_battle_ended(health_remaining: float, surrendered: bool) -> void :
	if health_remaining <= 0.0 or surrendered:
		show_battle_end_screen(false, false, false, surrendered)
		return

	print("Survived level %d" % GameManager.selected_level)
	var level: GameManager.Level = battle.level
	var earn_level_finished: bool = !level.has_survived
	level.has_survived = true
	level.stats.times_survived += 1
	if level.stats.first_time_survived <= 0:
		level.stats.first_time_survived = roundi(GameManager.total_time_played)
		level.stats.first_battle_time_survived = roundi(GameManager.total_battle_time)

	var killed_all: bool = is_equal_approx(health_remaining, Battle.get_max_health())
	var earn_all_killed: bool = killed_all and !level.has_killed_all

	if killed_all:
		level.has_killed_all = true
		level.stats.times_all_killed += 1
		if level.stats.first_time_all_killed <= 0:
			level.stats.first_time_all_killed = roundi(GameManager.total_time_played)
			level.stats.first_battle_time_all_killed = roundi(GameManager.total_battle_time)

	show_battle_end_screen(true, earn_level_finished, earn_all_killed, surrendered)

func _unhandled_input(event: InputEvent) -> void :
	if Menu.instance.visible:
		return

	if event is InputEventKey:
		if DevOptions.cheats_enabled and event.keycode == KEY_H and event.is_released():
			visible = !visible
		if DevOptions.cheats_enabled and event.keycode == KEY_J and event.is_released():
			%DebugContainer.visible = ! %DebugContainer.visible
		if event.keycode == KEY_R and event.is_released():
			if battle.phase == Battle.Phase.BUILD:
				for node: Node in %TowerPlacement.get_children():
					var tower: = node as BaseTower
					if tower:
						tower.deconstruct()

		if event.keycode == KEY_SPACE and event.is_released():
			try_to_start_battle()


func _on_battle_end_go_back_button_pressed() -> void :
	GPUSim.stop()
	Engine.time_scale = 1.0
	SceneTransition.change_scene(Constants.TECH_TREE_SCENE_PATH)


func _on_battle_end_restart_button_pressed() -> void :
	GameManager.load_level(GameManager.selected_level)


func show_controls_container() -> void :
	%ControlsContainer.visible = Options.show_battle_controls
	%ControlsButton.visible = !Options.show_battle_controls


func _on_controls_button_pressed(visible_in: bool) -> void :
	Options.show_battle_controls = visible_in
	SaveSystem.save_user_data()
	show_controls_container()


func _on_ability_button_toggled(toggled_on: bool, ability: int) -> void :
	if %ActiveAbilitiesSpawner.strafing_uses == 0:
		( %Abilities.get_child(1) as Button).disabled = true
	if %ActiveAbilitiesSpawner.nuke_uses == 0:
		( %Abilities.get_child(2) as Button).disabled = true
	if %ActiveAbilitiesSpawner.cryo_beam_remaining_time <= 0:
		( %Abilities.get_child(3) as Button).disabled = true

	if toggled_on:
		for i: int in %Abilities.get_child_count():
			( %Abilities.get_child(i) as Button).set_pressed_no_signal(ability == i + 1)
		%ActiveAbilitiesSpawner.active_ability = ability
	else:
		( %Abilities.get_child(ability - 1) as Button).set_pressed_no_signal(true)

func _on_start_battle_button_pressed() -> void :
	try_to_start_battle()

func try_to_start_battle() -> void :
	var any_tower_being_edited: bool = false
	for node: Node in %TowerPlacement.get_children():
		var tower: = node as BaseTower
		if tower and tower.edit_mode == BaseTower.EditMode.MOVABLE:
			any_tower_being_edited = true
			break

	if %TowerPlacement.current_tower == null and (TutorialManager.has_finished_tutorial or !TutorialManager.showing_battle_tutorial_2 or BaseTower.get_towers_built(BaseTower.TowerKind.GUNNER) > 0) and !any_tower_being_edited:
		battle.write_towers_to_level_progress()
		SaveSystem.save_save_data()
		battle.toggle_pause()
		%StartBattleButton.visible = false

func _on_hide_results_button_pressed() -> void :
	battle_end_container.visible = !battle_end_container.visible
	if battle_end_container.visible:
		%HideResultsButton.text = tr("Hide Results")
	else:
		%HideResultsButton.text = tr("Show Results")

func get_total_ability_damage() -> float:
	var total: float = 0.0
	for dmg: DamagePreset in damage_presets:
		if dmg.damage_report_id == Constants.DAMAGE_REPORT_ID_MISSILE or dmg.damage_report_id == Constants.DAMAGE_REPORT_ID_STRAFING_RUN or dmg.damage_report_id == Constants.DAMAGE_REPORT_ID_NUKE or dmg.damage_report_id == Constants.DAMAGE_REPORT_ID_CRYO_BEAM:
			total += GPUSim.contact_handlers_damage[dmg.damage_report_id]
	return total

func check_elemental_carnage_achievement() -> bool:
	for node: Node in %TowerPlacement.get_children():
		var tower: = node as BaseTower
		@warning_ignore("static_called_on_instance")
		if tower and tower.has_valid_placement and (tower.get_kind() != BaseTower.TowerKind.FLAMETHROWER and tower.get_kind() != BaseTower.TowerKind.TESLA_COIL):
			return false

	if get_total_ability_damage() != GPUSim.contact_handlers_damage[Constants.DAMAGE_REPORT_ID_CRYO_BEAM]:
		return false

	return true
