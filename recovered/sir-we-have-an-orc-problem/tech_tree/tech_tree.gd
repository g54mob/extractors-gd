extends Node

signal upgrades_changed

var _upgrades: Dictionary[StringName, Upgrade] = {}

func load_data(data: Dictionary) -> void :
	var upgrades_dict: Dictionary = data.get("upgrades", {})


	var upgrades_path: = "res://tech_tree/upgrades/"
	var files: PackedStringArray = DirAccess.get_files_at(upgrades_path)
	for f: String in files:
		f = f.trim_suffix(".remap")
		if !f.ends_with(".tres"):
			continue
		var resource_path: = upgrades_path + f
		var r: Resource = load(resource_path)
		if r is UpgradeData:
			var upgrade_save: Dictionary = upgrades_dict.get(r.id, {})
			var state: Upgrade.State = upgrade_save.get("state", 0)
			var level: int = upgrade_save.get("level", 0)
			_upgrades[r.id] = Upgrade.new(r, state, level)


	for u: Upgrade in _upgrades.values():
		for i: int in u.data.children.size():
			var cu: Upgrade = _upgrades.get(u.data.children[i].id, null)
			if cu:
				u.add_child(cu)


	var starting_upgrade: Upgrade = _upgrades[Constants.STARTING_UPGRADE_NAME]
	if starting_upgrade.state < Upgrade.State.READY:
		starting_upgrade.change_state(Upgrade.State.READY)

func save(data: Dictionary) -> void :
	var upgrades_dict: = {}
	for id: StringName in _upgrades.keys():
		var upgrade_save: Dictionary = {}
		upgrade_save["state"] = _upgrades[id].state
		upgrade_save["level"] = _upgrades[id].level
		upgrades_dict[id] = upgrade_save
	data["upgrades"] = upgrades_dict

func get_upgrade(upgrade_id: StringName) -> Upgrade:
	return _upgrades.get(upgrade_id)

func emit_upgrades_changed() -> void :
	upgrades_changed.emit()

	check_for_buy_all_achievement()

func check_for_buy_all_achievement() -> void :
	var result: bool = true
	for u_name: StringName in _upgrades.keys():
		if !_upgrades[u_name].is_max_level():
			result = false
			break

	if result:
		Achievements.set_achieved(Achievements.BUY_ALL)
