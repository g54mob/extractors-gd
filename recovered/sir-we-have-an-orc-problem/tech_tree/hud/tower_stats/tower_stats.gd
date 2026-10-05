extends PanelContainer

enum WeaponType{
	GUNNER, CANNON, MORTAR, FLAMETHROWER, TESLA_COIL, MISSILE, STRAFING_RUN, NUKE, GRENADE_LAUNCHER, LASER, CRYO_BEAM
}

@export var tower_kind: WeaponType

var labels: Array[TowerStatsLabel] = []

func _ready() -> void :
	visibility_changed.connect(update)
	TechTree.upgrades_changed.connect(update)

	%Name.text = get_tower_name(tower_kind)
	init_labels()

func get_tower_name(kind: WeaponType) -> String:
	match kind:
		WeaponType.GUNNER: return "Gunner"
		WeaponType.CANNON: return "Cannon"
		WeaponType.MORTAR: return "Mortar"
		WeaponType.FLAMETHROWER: return "Flamethrower"
		WeaponType.TESLA_COIL: return "Tesla Coil"
		WeaponType.MISSILE: return "Missile"
		WeaponType.STRAFING_RUN: return "Strafing Run"
		WeaponType.NUKE: return "Nuke"
		WeaponType.GRENADE_LAUNCHER: return "Grenade Launcher"
		WeaponType.LASER: return "Laser"
		WeaponType.CRYO_BEAM: return "Orbital Cryo Beam"
		_:
			assert (false, "Missing tower name!")
			return "BaseTower"

func init_labels() -> void :
	match tower_kind:
		WeaponType.GUNNER:
			add_label("Available Towers")
			add_spacing()
			add_label("Fire Rate")
			add_label("Damage")
			add_label("Range")
			add_label("Penetration")

		WeaponType.MORTAR:
			add_label("Available Towers")
			add_spacing()
			add_label("Fire Rate")
			add_label("Damage")
			add_label("Radius")
			add_spacing()
			add_label("Shrapnel")
			add_label("Shrapnel Damage")
			add_label("Shrapnel Penetration")

		WeaponType.CANNON:
			add_label("Available Towers")
			add_spacing()
			add_label("Fire Rate")
			add_label("Damage")
			add_label("Range")
			add_label("Penetration")

		WeaponType.FLAMETHROWER:
			add_label("Available Towers")
			add_spacing()
			add_label("Range")
			add_spacing()
			add_label("Burn Duration")
			add_label("Burn Tick Rate")
			add_label("Burn Tick Damage")
			add_spacing()
			add_label("Bonus Damage")

		WeaponType.TESLA_COIL:
			add_label("Available Towers")
			add_spacing()
			add_label("Fire Rate")
			add_label("Damage")
			add_label("Range")
			add_label("Chain Jumps")
			add_label("Shock Duration")

		WeaponType.MISSILE:
			add_label("Damage")
			add_label("Radius")
			add_label("Cooldown")
			add_spacing()
			add_label("Shrapnel")
			add_label("Damage")
			add_label("Penetration")
			add_label("Slow Strength")
			add_label("Slow Duration")

		WeaponType.STRAFING_RUN:
			add_label("Available Planes")
			add_spacing()
			add_label("Damage")
			add_label("Radius")
			add_label("Area Width")
			add_label("Area Length")
			add_label("Bullets")

		WeaponType.NUKE:
			add_label("Available Bombs")
			add_spacing()
			add_label("Damage")
			add_label("Radius")

		WeaponType.GRENADE_LAUNCHER:
			add_label("Available Towers")
			add_spacing()
			add_label("Volley Size")
			add_label("Reload Time")
			add_spacing()
			add_label("Grenade Duration")
			add_label("Grenade Effect Radius")
			add_spacing()
			add_label("Slow Strength")
			add_label("Slow Duration")
			add_spacing()
			add_label("Explosion Damage")
			add_label("Explosion Radius")
			add_spacing()
			add_label("Bonus Damage")

		WeaponType.LASER:
			add_label("Available Towers")
			add_spacing()
			add_label("Fire Rate")
			add_label("Damage")
			add_label("Range")
			add_label("Max Bounces")

		WeaponType.CRYO_BEAM:
			add_label("Fuel Tank")
			add_spacing()
			add_label("Radius")
			add_label("Freeze Duration")
			add_label("Damage")


func add_label(caption: String) -> void :
	var label: TowerStatsLabel = Constants.tower_stats_label_scene.instantiate()
	label.initialize(caption)
	%VBoxContainer.add_child(label)
	labels.append(label)

func add_spacing() -> void :
	var spacing: = Control.new()
	spacing.custom_minimum_size.y = 5
	%VBoxContainer.add_child(spacing)

func update() -> void :
	if !visible:
		return

	match tower_kind:
		WeaponType.GUNNER:
			labels[0].set_value(str(BaseTower.get_tower_limit(BaseTower.TowerKind.GUNNER)))
			labels[1].set_value(tr("{x} / s").format({"x": NumberFormatter.format_float(Gunner.get_firerate(), 2)}))
			labels[2].set_value(NumberFormatter.format_float(Gunner.get_damage(), 2))
			labels[3].set_value(tr("{x} m").format({"x": NumberFormatter.format_float(Gunner.get_range(), 0)}))
			labels[4].set_value("%d" % (Gunner.get_bullet_health() - 1))

			var has_penetration: bool = Gunner.get_bullet_health() > 1
			labels[4].visible = has_penetration

		WeaponType.MORTAR:
			labels[0].set_value(str(BaseTower.get_tower_limit(BaseTower.TowerKind.MORTAR)))
			labels[1].set_value(tr("{x} / s").format({"x": NumberFormatter.format_float(Mortar.get_firerate(), 2)}))
			labels[2].set_value(NumberFormatter.format_float(Mortar.get_explosion_damage(), 2))
			labels[3].set_value(tr("{x} m").format({"x": NumberFormatter.format_float(Mortar.get_explosion_radius(), 0)}))
			labels[4].set_value("%d" % Mortar.get_fragment_count())
			labels[5].set_value(NumberFormatter.format_float(Mortar.get_fragment_damage(), 2))
			labels[6].set_value("%d" % (Mortar.get_fragment_health() - 1))

			var has_mortar_fragment: bool = TechTree.get_upgrade(&"mortar_fragment_count").level > 0
			labels[4].visible = has_mortar_fragment
			labels[5].visible = has_mortar_fragment
			labels[6].visible = has_mortar_fragment

		WeaponType.CANNON:
			labels[0].set_value(str(BaseTower.get_tower_limit(BaseTower.TowerKind.CANNON)))
			labels[1].set_value(tr("{x} / s").format({"x": NumberFormatter.format_float(Cannon.get_firerate(), 2)}))
			labels[2].set_value(NumberFormatter.format_float(Cannon.get_damage(), 2))
			labels[3].set_value(tr("{x} m").format({"x": NumberFormatter.format_float(Cannon.get_range(), 0)}))
			labels[4].set_value("%d" % (Cannon.get_bullet_health() - 1))

		WeaponType.FLAMETHROWER:
			labels[0].set_value(str(BaseTower.get_tower_limit(BaseTower.TowerKind.FLAMETHROWER)))
			labels[1].set_value(tr("{x} m").format({"x": NumberFormatter.format_float(Flamethrower.get_range(), 0)}))
			labels[2].set_value(tr("{x} s").format({"x": NumberFormatter.format_float(Flamethrower.get_fire_timer(), 2)}))
			labels[3].set_value(tr("{x} / s").format({"x": NumberFormatter.format_float(Flamethrower.get_fire_tick_rate(), 2)}))
			labels[4].set_value(NumberFormatter.format_float(Flamethrower.get_fire_tick_damage(), 2))
			labels[5].set_value(tr("{x}%").format({"x": NumberFormatter.format(Flamethrower.get_damage_multiplier_percentage())}))

			var has_bonus_damage_unlocked: bool = Flamethrower.get_damage_multiplier_percentage() > 0
			labels[5].visible = has_bonus_damage_unlocked

		WeaponType.TESLA_COIL:
			labels[0].set_value(str(BaseTower.get_tower_limit(BaseTower.TowerKind.TESLA_COIL)))
			labels[1].set_value(tr("{x} / s").format({"x": NumberFormatter.format_float(TeslaCoil.get_firerate(), 2)}))
			labels[2].set_value(NumberFormatter.format_float(TeslaCoil.get_damage(), 2))
			labels[3].set_value(tr("{x} m").format({"x": NumberFormatter.format_float(TeslaCoil.get_range(), 0)}))
			labels[4].set_value("%d" % TeslaCoil.get_chaining())
			labels[5].set_value(("{x} s").format({"x": NumberFormatter.format_float(TeslaCoil.get_shock_duration(), 2)}))

			var has_confusion_unlocked: bool = TeslaCoil.get_shock_duration() > 0
			labels[5].visible = has_confusion_unlocked

		WeaponType.MISSILE:
			labels[0].set_value(NumberFormatter.format_float(Missile.get_damage(), 2))
			labels[1].set_value(tr("{x} m").format({"x": NumberFormatter.format_float(Missile.get_radius(), 0)}))
			labels[2].set_value(tr("{x} s").format({"x": NumberFormatter.format_float(Missile.get_cooldown(), 1)}))
			labels[3].set_value("%d" % Missile.get_shrapnel_count())
			labels[4].set_value(NumberFormatter.format_float(Missile.get_shrapnel_damage(), 2))
			labels[5].set_value("%d" % (Missile.get_shrapnel_health() - 1))
			labels[6].set_value(tr("{x}%").format({"x": NumberFormatter.format(Missile.get_shrapnel_slow_strength())}))
			labels[7].set_value(tr("{x} s").format({"x": NumberFormatter.format_float(Missile.get_shrapnel_slow_duration(), 2)}))

			var has_missile_shrapnel: bool = Missile.get_shrapnel_count() > 0
			labels[3].visible = has_missile_shrapnel
			labels[4].visible = has_missile_shrapnel
			labels[5].visible = has_missile_shrapnel
			labels[6].visible = has_missile_shrapnel
			labels[7].visible = has_missile_shrapnel

		WeaponType.STRAFING_RUN:
			labels[0].set_value(str(StrafingRun.get_uses()))
			labels[1].set_value(NumberFormatter.format_float(StrafingRun.get_damage(), 2))
			labels[2].set_value(tr("{x} m").format({"x": NumberFormatter.format_float(StrafingRun.get_radius(), 0)}))
			labels[3].set_value(tr("{x} m").format({"x": NumberFormatter.format_float(StrafingRun.get_width(), 2)}))
			labels[4].set_value(tr("{x} m").format({"x": NumberFormatter.format_float(StrafingRun.get_length(), 2)}))
			labels[5].set_value("%d" % StrafingRun.get_bullet_count())

		WeaponType.NUKE:
			labels[0].set_value(str(Nuke.get_uses()))
			labels[1].set_value(NumberFormatter.format_float(Nuke.get_damage(), 2))
			labels[2].set_value(tr("{x} m").format({"x": NumberFormatter.format_float(Nuke.get_radius(), 0)}))

		WeaponType.GRENADE_LAUNCHER:
			labels[0].set_value(str(BaseTower.get_tower_limit(BaseTower.TowerKind.GRENADE_LAUNCHER)))
			labels[1].set_value("%d" % GrenadeLauncher.get_volley_size())
			labels[2].set_value(tr("{x} s").format({"x": NumberFormatter.format_float(GrenadeLauncher.BASE_RELOAD_TIME, 2)}))
			labels[3].set_value(tr("{x} s").format({"x": NumberFormatter.format_float(GrenadeLauncher.get_grenade_lifetime(), 2)}))
			labels[4].set_value(tr("{x} m").format({"x": NumberFormatter.format_float(GrenadeLauncher.get_grenade_radius(), 0)}))
			labels[5].set_value(tr("{x}%").format({"x": roundi(GrenadeLauncher.get_slow_strength())}))
			labels[6].set_value(tr("{x} s").format({"x": NumberFormatter.format_float(GrenadeLauncher.get_slow_duration(), 2)}))
			labels[7].set_value(NumberFormatter.format_float(GrenadeLauncher.get_explosion_damage(), 2))
			labels[8].set_value(tr("{x} m").format({"x": NumberFormatter.format_float(GrenadeLauncher.get_explosion_radius(), 0)}))
			labels[9].set_value(tr("{x}%").format({"x": NumberFormatter.format(GrenadeLauncher.get_damage_multiplier_percentage())}))

			var has_explosive_grenades: bool = TechTree.get_upgrade(&"grenade_launcher_explosive").level > 0
			labels[7].visible = has_explosive_grenades
			labels[8].visible = has_explosive_grenades

			var has_bonus_damage_unlocked: bool = GrenadeLauncher.get_damage_multiplier_percentage() > 0
			labels[9].visible = has_bonus_damage_unlocked

		WeaponType.LASER:
			labels[0].set_value(str(BaseTower.get_tower_limit(BaseTower.TowerKind.LASER)))
			labels[1].set_value(tr("{x} / s").format({"x": NumberFormatter.format_float(Laser.get_fire_rate(), 2)}))
			labels[2].set_value(NumberFormatter.format_float(Laser.get_damage(), 2))
			labels[3].set_value(tr("{x} m").format({"x": NumberFormatter.format_float(Laser.get_range(), 0)}))
			labels[4].set_value("%d" % Laser.get_max_bounces())

		WeaponType.CRYO_BEAM:
			labels[0].set_value(tr("{x} s").format({"x": NumberFormatter.format_float(CryoBeam.get_fuel(), 2)}))
			labels[1].set_value(tr("{x} m").format({"x": NumberFormatter.format_float(CryoBeam.get_radius(), 0)}))
			labels[2].set_value(tr("{x} s").format({"x": NumberFormatter.format_float(CryoBeam.get_freeze_duration(), 2)}))
			labels[3].set_value(NumberFormatter.format_float(CryoBeam.get_unfreeze_damage(), 2))

			labels[3].visible = CryoBeam.get_unfreeze_damage() > 0


func only_for_localization() -> void :
	tr("Available Towers")
	tr("Fire Rate")
	tr("Damage")
	tr("Range")
	tr("Penetration")
	tr("Radius")
	tr("Shrapnel")
	tr("Shrapnel Damage")
	tr("Shrapnel Penetration")
	tr("Burn Duration")
	tr("Burn Tick Rate")
	tr("Burn Tick Damage")
	tr("Cooldown")
	tr("Area Width")
	tr("Bullets")
	tr("Shock Duration")
	tr("Bonus Damage")
	tr("Chain Jumps")
	tr("Volley Size")
	tr("Reload Time")
	tr("Slow Strength")
	tr("Slow Duration")
	tr("Available Planes")
	tr("Available Bombs")
	tr("Explosion Radius")
	tr("Max Bounces")
	tr("Fuel Tank")
	tr("Freeze Duration")
	tr("Area Length")
	tr("Explosion Damage")
