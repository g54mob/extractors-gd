extends Node

const SURVIVE_1: StringName = &"ACH_SURVIVE_1"
const SURVIVE_3: StringName = &"ACH_SURVIVE_3"
const SURVIVE_6: StringName = &"ACH_SURVIVE_6"
const ONE_TOWER: StringName = &"ACH_SURVIVE_ONE_TOWER"
const NO_TOWERS: StringName = &"ACH_SURVIVE_NO_TOWERS"
const ONE_TOWER_TYPE: StringName = &"ACH_SURVIVE_ONE_TOWER_TYPE"
const ELEMENTAL: StringName = &"ACH_SURVIVE_ELEMENTAL"
const THREE_TOWER_TYPE: StringName = &"ACH_SURVIVE_THREE_TOWER_TYPE"
const FOUR_TOWER_TYPE: StringName = &"ACH_SURVIVE_FOUR_TOWER_TYPE"
const BUY_ALL: StringName = &"ACH_BUY_ALL"
const NUKE: StringName = &"ACH_NUKE"

func set_achieved(ach: StringName) -> void :
	if OS.has_feature("demo"):
		return

	if not Steam.setAchievement(ach):
		printerr("Failed to set achievement: %s" % ach)
		return

	if not Steam.storeStats():
		printerr("Failed to store data on Steam, should be stored locally")
		return

func reset_stats_and_achievements() -> void :
	Steam.resetAllStats(true)
