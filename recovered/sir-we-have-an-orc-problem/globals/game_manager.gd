extends Node

signal currency_changed(type: Currency.Type, amount: int)

var has_supporter_pack: bool = false

var selected_level: int:
	set(value):
		selected_level = value

const ENEMY_MIN_RADIUS: float = 2.0
const ENEMY_MAX_RADIUS: float = 4.0
const ENEMY_HEALTH_BUFF_OVER_TIME: float = 1.0
const ENEMY_HEALTH_BUFF_RADIUS: float = 0.2
const BASE_KILL_COUNT_DIVISOR: float = 20.0

func get_enemy_health(radius: float, relative_time: float, level: Level) -> float:
	var radius_f: = (radius * radius) * ENEMY_HEALTH_BUFF_RADIUS
	var time_f: = (1.0 + relative_time * ENEMY_HEALTH_BUFF_OVER_TIME)
	var level_f: = level.data.enemy_health_buff
	return radius_f * time_f * level_f

func get_kill_count_divisor() -> float:
	return (BASE_KILL_COUNT_DIVISOR
		- TechTree.get_upgrade(&"headhunter").current_value)

class Level:
	class Stats:
		var times_started: int = 0
		var times_survived: int = 0
		var times_all_killed: int = 0
		var first_time_started: int = 0
		var first_time_survived: int = 0
		var first_time_all_killed: int = 0
		var first_battle_time_started: int = 0
		var first_battle_time_survived: int = 0
		var first_battle_time_all_killed: int = 0
		var total_marks_earned: int = 0
	var name: StringName
	var data: LevelData
	var has_survived: bool = false
	var has_killed_all: bool = false
	var towers: Array[Dictionary] = []
	var stats: Stats = Stats.new()
	func _init(name_in: StringName, data_in: LevelData) -> void :
		name = name_in
		data = data_in

var levels: Dictionary[int, Level] = {}

var currency_amounts: Dictionary[Currency.Type, int] = {
	Currency.Type.UPGRADE_MARKS: 0, 
	Currency.Type.LEVEL_FINISHED: 0, 
	Currency.Type.ALL_KILLED_CHALLENGE: 0
}

var upgrade_marks_spent: int = 0
func get_additional_cost() -> int:
	return int(pow(upgrade_marks_spent / 20.0, 0.7))

var has_seen_tower_stats: Dictionary[String, bool] = {}

const LEVELS_DIR: = "res://levels"
func _ready() -> void :
	process_mode = Node.PROCESS_MODE_ALWAYS
	Steamy.initialized.connect( func() -> void :
		has_supporter_pack = Steamy.has_supporter_pack, 
		CONNECT_ONE_SHOT)


var total_time_played: float = 0.0
var total_battle_time: float = 0.0
var should_count_battle_time: bool = false
func _process(delta: float) -> void :
	total_time_played += delta
	if should_count_battle_time:
		total_battle_time += delta

func load_data(data: Dictionary) -> void :
	for currency: Currency.Type in Currency.Type.values():
		currency_amounts[currency] = data.get(Currency.Type.keys()[currency], 0)

	upgrade_marks_spent = data.get("upgrade_marks_spent", 0)


	levels[1] = GameManager.Level.new(tr("Level") + " 1.1", load("res://levels/level_1_1/level_1_1.tres"))
	levels[2] = GameManager.Level.new(tr("Level") + " 1.2", load("res://levels/level_1_2/level_1_2.tres"))
	levels[3] = GameManager.Level.new(tr("Level") + " 2.1", load("res://levels/level_2_1/level_2_1.tres"))
	levels[4] = GameManager.Level.new(tr("Level") + " 2.2", load("res://levels/level_2_2/level_2_2.tres"))
	levels[5] = GameManager.Level.new(tr("Level") + " 3.1", load("res://levels/level_3_1/level_3_1.tres"))
	levels[6] = GameManager.Level.new(tr("Level") + " 3.2", load("res://levels/level_3_2/level_3_2.tres"))
	levels[7] = GameManager.Level.new(tr("Level") + " 4.1", load("res://levels/level_4_1/level_4_1.tres"))
	levels[8] = GameManager.Level.new(tr("Level") + " 4.2", load("res://levels/level_4_2/level_4_2.tres"))
	levels[9] = GameManager.Level.new(tr("Level") + " 5.1", load("res://levels/level_5_1/level_5_1.tres"))
	levels[10] = GameManager.Level.new(tr("Level") + " 5.2", load("res://levels/level_5_2/level_5_2.tres"))
	levels[11] = GameManager.Level.new(tr("Level") + " 6.1", load("res://levels/level_6_1/level_6_1.tres"))
	levels[12] = GameManager.Level.new(tr("Level") + " 6.2", load("res://levels/level_6_2/level_6_2.tres"))

	var levels_dict: Dictionary = data.get("levels", {})
	for level_id: int in levels.keys():
		var level_dict: Dictionary = levels_dict.get(str(level_id), {})
		var level: = levels[level_id]
		level.has_survived = level_dict.get("has_survived", false)
		level.has_killed_all = level_dict.get("has_killed_all", false)
		level.towers.clear()
		level.towers.append_array(level_dict.get("towers", []))
		var stats_dict: Dictionary = level_dict.get("stats", {})
		level.stats.times_started = stats_dict.get("times_started", 0)
		level.stats.times_survived = stats_dict.get("times_survived", 0)
		level.stats.times_all_killed = stats_dict.get("times_all_killed", 0)
		level.stats.first_time_started = stats_dict.get("first_time_started", 0)
		level.stats.first_time_survived = stats_dict.get("first_time_survived", 0)
		level.stats.first_time_all_killed = stats_dict.get("first_time_all_killed", 0)
		level.stats.first_battle_time_started = stats_dict.get("first_battle_time_started", 0)
		level.stats.first_battle_time_survived = stats_dict.get("first_battle_time_survived", 0)
		level.stats.first_battle_time_all_killed = stats_dict.get("first_battle_time_all_killed", 0)
		level.stats.total_marks_earned = stats_dict.get("total_marks_earned", 0)


	var hsts: Dictionary = data.get("has_seen_tower_stats", {})
	for key: String in hsts.keys():
		has_seen_tower_stats[key] = hsts[key]

	total_time_played = float(data.get("total_time_played", 0))
	total_battle_time = float(data.get("total_battle_time", 0))

func save(data: Dictionary) -> void :
	for currency: Currency.Type in Currency.Type.values():
		data[Currency.Type.keys()[currency]] = currency_amounts.get(currency, 0)

	data["upgrade_marks_spent"] = upgrade_marks_spent

	var levels_dict: Dictionary
	for level_id: int in levels:
		var level: = levels[level_id]

		var stats_dict: Dictionary = {
			"times_started": level.stats.times_started, 
			"times_survived": level.stats.times_survived, 
			"times_all_killed": level.stats.times_all_killed, 
			"first_time_started": level.stats.first_time_started, 
			"first_time_survived": level.stats.first_time_survived, 
			"first_time_all_killed": level.stats.first_time_all_killed, 
			"first_battle_time_started": level.stats.first_battle_time_started, 
			"first_battle_time_survived": level.stats.first_battle_time_survived, 
			"first_battle_time_all_killed": level.stats.first_battle_time_all_killed, 
			"total_marks_earned": level.stats.total_marks_earned, 
		}

		levels_dict[str(level_id)] = {
			"has_survived": level.has_survived, 
			"has_killed_all": level.has_killed_all, 
			"towers": level.towers, 
			"stats": stats_dict
		}
	data["levels"] = levels_dict
	data["has_seen_tower_stats"] = has_seen_tower_stats
	data["total_time_played"] = roundi(total_time_played)
	data["total_battle_time"] = roundi(total_battle_time)


func load_level(level: int) -> void :
	selected_level = level
	GPUSim.reset()
	levels[level].stats.times_started += 1
	if levels[level].stats.first_time_started <= 0:
		levels[level].stats.first_time_started = roundi(total_time_played)
		levels[level].stats.first_battle_time_started = roundi(GameManager.total_battle_time)
	SceneTransition.change_scene(Constants.BATTLE_SCENE_PATH)

func spend_currency(type: Currency.Type, amount: int) -> bool:
	if currency_amounts.get(type, 0) >= amount:
		currency_amounts[type] -= amount
		if type == Currency.Type.UPGRADE_MARKS:
			upgrade_marks_spent += amount
		currency_changed.emit(type, currency_amounts[type])
		return true
	return false

func earn_currency(type: Currency.Type, amount: int) -> void :
	currency_amounts[type] += amount
	currency_changed.emit(type, currency_amounts[type])

func _unhandled_key_input(event: InputEvent) -> void :
	if SceneTransition.is_transitioning:
		return

	if event.is_action_pressed("ui_cancel"):
		Menu.show_menu()
		get_viewport().set_input_as_handled()
