class_name CryoBeam extends Node

static func is_unlocked() -> bool:
	return TechTree.get_upgrade(&"cryo_beam_unlock").level > 0

const BASE_FUEL: float = 3.0
static func get_fuel() -> float:
	return (BASE_FUEL
		+ TechTree.get_upgrade(&"cryo_beam_fuel").current_value
		+ TechTree.get_upgrade(&"cryo_beam_fuel_2").current_value
	)

const BASE_RADIUS: float = 4.0
static func get_radius() -> float:
	return (BASE_RADIUS
		+ TechTree.get_upgrade(&"cryo_beam_radius").current_value
		+ TechTree.get_upgrade(&"cryo_beam_radius_2").current_value
	)

const BASE_FREEZE_DURATION: float = 2.0
static func get_freeze_duration() -> float:
	return (BASE_FREEZE_DURATION
		+ TechTree.get_upgrade(&"cryo_beam_duration").current_value
		+ TechTree.get_upgrade(&"cryo_beam_duration_2").current_value
	)

static func get_unfreeze_damage() -> float:
	return (TechTree.get_upgrade(&"cryo_beam_damage").current_value
		+ TechTree.get_upgrade(&"cryo_beam_damage_2").current_value
		+ TechTree.get_upgrade(&"cryo_beam_damage_3").current_value
	)
