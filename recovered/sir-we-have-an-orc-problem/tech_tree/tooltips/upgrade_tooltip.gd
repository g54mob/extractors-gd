class_name UpgradeTooltip extends Control


func set_data(upgrade: Upgrade) -> void :

	%CaptionLabel.text = upgrade.data.name
	%ProgressLabel.text = "%d/%d" % [upgrade.level, upgrade.data.max_level]
	%DescriptionLabel.text = tr(upgrade.data.description).format(
		{
			"x": get_base_value_text(upgrade), 
			"upgrade_mark": "[img=center,center]res://tech_tree/hud/upgrade_mark.png[/img]", 
			"pink_upgrade": "[img=center,center]res://tech_tree/hud/all_killed_mark.png[/img]", 
			"straf_len": NumberFormatter.format_float(StrafingRun.LENGTH_PER_LEVEL)
		})

	if is_equal_approx(upgrade.data.value, 0):
		%ValuesLabel.visible = false
	else:
		%ValuesLabel.text = get_current_value_text(upgrade)

	if upgrade.data.id.begins_with("strafing_run_width"):
		%ValuesLabel.custom_minimum_size.y = %ValuesLabel.custom_minimum_size.y * 2
		if upgrade.is_max_level():
			%ValuesLabel.text += "\n(%s)" % NumberFormatter.format_float(StrafingRun.get_length())
		else:
			%ValuesLabel.text += "\n(%s [img=center,center]res://tech_tree/tooltips/values_arrow_white.png[/img] %s))" % [NumberFormatter.format_float(StrafingRun.get_length()), NumberFormatter.format_float(StrafingRun.get_length() + StrafingRun.LENGTH_PER_LEVEL)]

	if upgrade.is_max_level():
		%CostHBox.visible = false
	else:
		%CostLabel.text = NumberFormatter.format(upgrade.cost)
		%CostLabel.self_modulate = Color.WHITE if upgrade.can_afford() else Color.ORANGE_RED
		%CurrencyTextureRect.texture = Currency.ICONS[upgrade.data.currency]

	var is_demo: = OS.has_feature("demo")
	%NotImplementedLabel.visible = !is_demo and !upgrade.data.is_implemented
	%FullGameLabel.visible = !upgrade.data.is_in_demo or (is_demo and !upgrade.data.is_implemented)

	update_description_min_size.call_deferred()

func update_description_min_size() -> void :
	%DescriptionLabel.custom_minimum_size.y = %DescriptionLabel.get_content_height()

func get_base_value_text(upgrade: Upgrade) -> String:
	match upgrade.data.value_display_type:
		UpgradeData.ValueDisplayType.INT:
			return str(roundi(upgrade.data.value))
		UpgradeData.ValueDisplayType.FLOAT:
			return NumberFormatter.format_float(upgrade.data.value, 2)
		_:
			assert (false, "What's the type?!")
			return ""

func get_current_value_text(upgrade: Upgrade) -> String:
	match upgrade.data.value_display_type:
		UpgradeData.ValueDisplayType.INT:
			var value: int = roundi(get_absolute_value(upgrade))
			if upgrade.is_max_level():
				return "(%d)" % value
			else:
				var next_level_value: int = roundi(value + upgrade.data.value)
				if upgrade.data.id.begins_with("headhunter"):
					next_level_value = roundi(value - upgrade.data.value)
				return "(%d [img=center,center]res://tech_tree/tooltips/values_arrow_white.png[/img] %d)" % [value, next_level_value]
		UpgradeData.ValueDisplayType.FLOAT:
			var value: float = get_absolute_value(upgrade)
			if upgrade.is_max_level():
				return "(%s)" % NumberFormatter.format_float(value, 2)
			else:
				var next_level_value: float = value + upgrade.data.value
				if upgrade.data.id.begins_with("headhunter"):
					next_level_value = value - upgrade.data.value
				return "(%s [img=center,center]res://tech_tree/tooltips/values_arrow_white.png[/img] %s)" % [
					NumberFormatter.format_float(value, 2), 
					NumberFormatter.format_float(next_level_value, 2)
				]
		_:
			assert (false, "This should never happen.")
			return ""

func get_absolute_value(upgrade: Upgrade) -> float:
	if upgrade.data.id.contains("_count"):
		if upgrade.data.id.begins_with("mortar_frag"):
			return Mortar.get_fragment_count()
		elif upgrade.data.id.begins_with("strafing_run_bullet"):
			return StrafingRun.get_bullet_count()
		elif upgrade.data.id.begins_with("strafing_run"):
			return StrafingRun.get_uses()
		elif upgrade.data.id.begins_with("nuke"):
			return Nuke.get_uses()
		elif upgrade.data.id.begins_with("missile_shrapnel"):
			return Missile.get_shrapnel_count()
		else:
			return BaseTower.get_tower_limit(get_tower_kind_from_upgrade_id(upgrade.data.id))

	elif upgrade.data.id.contains("_firerate"):
		if upgrade.data.id.begins_with("gunner"):
			return Gunner.get_firerate()
		elif upgrade.data.id.begins_with("cannon"):
			return Cannon.get_firerate()
		elif upgrade.data.id.begins_with("mortar"):
			return Mortar.get_firerate()
		elif upgrade.data.id.begins_with("tesla"):
			return TeslaCoil.get_firerate()
		elif upgrade.data.id.begins_with("laser"):
			return Laser.get_fire_rate()

	elif upgrade.data.id.contains("_damage"):
		if upgrade.data.id.begins_with("gunner"):
			return Gunner.get_damage()
		elif upgrade.data.id.begins_with("cannon"):
			return Cannon.get_damage()
		elif upgrade.data.id.begins_with("fire_damage_buff"):
			return Flamethrower.get_damage_multiplier_percentage()
		elif upgrade.data.id.begins_with("fire"):
			return Flamethrower.get_fire_tick_damage()
		elif upgrade.data.id.begins_with("mortar_expl"):
			return Mortar.get_explosion_damage()
		elif upgrade.data.id.begins_with("mortar_frag"):
			return Mortar.get_fragment_damage()
		elif upgrade.data.id.begins_with("missile_shrapnel"):
			return Missile.get_shrapnel_damage()
		elif upgrade.data.id.begins_with("missile"):
			return Missile.get_damage()
		elif upgrade.data.id.begins_with("strafing"):
			return StrafingRun.get_damage()
		elif upgrade.data.id.begins_with("tesla"):
			return TeslaCoil.get_damage()
		elif upgrade.data.id.begins_with("grenade_launcher_damage_buff"):
			return GrenadeLauncher.get_damage_multiplier_percentage()
		elif upgrade.data.id.begins_with("grenade"):
			return GrenadeLauncher.get_explosion_damage()
		elif upgrade.data.id.begins_with("explosive_orcs"):
			return EnemySpawner.get_explosive_orcs_damage()
		elif upgrade.data.id.begins_with("nuke"):
			return Nuke.get_damage()
		elif upgrade.data.id.begins_with("laser"):
			return Laser.get_damage()
		elif upgrade.data.id.begins_with("cryo"):
			return CryoBeam.get_unfreeze_damage()

	elif upgrade.data.id.contains("_range"):
		if upgrade.data.id.begins_with("gunner"):
			return Gunner.get_range()
		elif upgrade.data.id.begins_with("cannon"):
			return Cannon.get_range()
		elif upgrade.data.id.begins_with("flamethrower"):
			return Flamethrower.get_range()
		elif upgrade.data.id.begins_with("tesla"):
			return TeslaCoil.get_range()
		elif upgrade.data.id.begins_with("laser"):
			return Laser.get_range()

	elif upgrade.data.id.contains("_penetration"):
		if upgrade.data.id.begins_with("gunner"):
			return Gunner.get_bullet_health() - 1
		elif upgrade.data.id.begins_with("cannon"):
			return Cannon.get_bullet_health() - 1
		elif upgrade.data.id.begins_with("mortar"):
			return Mortar.get_fragment_health() - 1
		elif upgrade.data.id.begins_with("missile_shrapnel"):
			return Missile.get_shrapnel_health() - 1

	elif upgrade.data.id.begins_with("mortar_explosion_radius"):
		return Mortar.get_explosion_radius()

	elif upgrade.data.id.begins_with("base_hp"):
		return Battle.get_max_health()

	elif upgrade.data.id.begins_with("fire_tick_rate"):
		return Flamethrower.get_fire_tick_rate()

	elif upgrade.data.id.begins_with("flamethrower_fire_duration"):
		return Flamethrower.get_fire_timer()

	elif upgrade.data.id.begins_with("missile_radius"):
		return Missile.get_radius()

	elif upgrade.data.id.begins_with("missile_cooldown"):
		return Missile.get_cooldown()

	elif upgrade.data.id.begins_with("strafing_run_width"):
		return StrafingRun.get_width()

	elif upgrade.data.id.begins_with("strafing_run_radius"):
		return StrafingRun.get_radius()

	elif upgrade.data.id.begins_with("headhunter"):
		return GameManager.get_kill_count_divisor()

	elif upgrade.data.id.begins_with("tesla_coil_chaining"):
		return TeslaCoil.get_chaining()

	elif upgrade.data.id.begins_with("grenade_launcher_volley"):
		return GrenadeLauncher.get_volley_size()

	elif upgrade.data.id.begins_with("grenade_launcher_lifetime"):
		return GrenadeLauncher.get_grenade_lifetime()

	elif upgrade.data.id.begins_with("grenade_launcher_radius"):
		return GrenadeLauncher.get_grenade_radius()

	elif upgrade.data.id.begins_with("grenade_launcher_slow_strength"):
		return GrenadeLauncher.get_slow_strength()

	elif upgrade.data.id.begins_with("grenade_launcher_slow_duration"):
		return GrenadeLauncher.get_slow_duration()

	elif upgrade.data.id.begins_with("grenade_launcher_explosion_radius"):
		return GrenadeLauncher.get_explosion_radius()

	elif upgrade.data.id.begins_with("explosive_orcs_chance"):
		return EnemySpawner.get_explosive_orcs_chance()

	elif upgrade.data.id.begins_with("explosive_orcs_radius"):
		return EnemySpawner.get_explosive_orcs_radius()

	elif upgrade.data.id.begins_with("nuke_radius"):
		return Nuke.get_radius()

	elif upgrade.data.id.begins_with("tesla_coil_shock_duration"):
		return TeslaCoil.get_shock_duration()


	elif upgrade.data.id.begins_with("missile_shrapnel_slow_duration"):
		return Missile.get_shrapnel_slow_duration()

	elif upgrade.data.id.begins_with("missile_shrapnel_slow_strength"):
		return Missile.get_shrapnel_slow_strength()

	elif upgrade.data.id.begins_with("golden_orcs_money"):
		return EnemySpawner.get_golden_orc_money()

	elif upgrade.data.id.begins_with("golden_orcs"):
		return EnemySpawner.get_golden_orc_chance()

	elif upgrade.data.id.begins_with("laser_bounces"):
		return Laser.get_max_bounces()

	elif upgrade.data.id.begins_with("cryo_beam_fuel"):
		return CryoBeam.get_fuel()

	elif upgrade.data.id.begins_with("cryo_beam_radius"):
		return CryoBeam.get_radius()

	elif upgrade.data.id.begins_with("cryo_beam_duration"):
		return CryoBeam.get_freeze_duration()

	return upgrade.current_value

func get_tower_kind_from_upgrade_id(id: StringName) -> BaseTower.TowerKind:
	if id.begins_with("gunner"):
		return BaseTower.TowerKind.GUNNER
	elif id.begins_with("cannon"):
		return BaseTower.TowerKind.CANNON
	elif id.begins_with("minigun_robot"):
		return BaseTower.TowerKind.MINIGUN_ROBOT
	elif id.begins_with("mortar"):
		return BaseTower.TowerKind.MORTAR
	elif id.begins_with("flamethrower"):
		return BaseTower.TowerKind.FLAMETHROWER
	elif id.begins_with("tesla"):
		return BaseTower.TowerKind.TESLA_COIL
	elif id.begins_with("grenade"):
		return BaseTower.TowerKind.GRENADE_LAUNCHER
	elif id.begins_with("laser"):
		return BaseTower.TowerKind.LASER

	assert (false, "No kind available")
	return BaseTower.TowerKind.GUNNER
