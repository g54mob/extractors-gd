extends Node

const USER_SAVE_PATH: = "user://user.save"
const SAVE_PATH: = "user://save_%d.save"
const SAVE_SLOT: = "save_slot"
const MAX_SAVE_SLOTS: = 3

var current_save_slot: int = -1

func load_user_data() -> Dictionary:
	var user_data: Dictionary = read_file(USER_SAVE_PATH)
	current_save_slot = user_data.get(SAVE_SLOT, -1)
	return user_data

func load_save_data(slot: int = -1) -> Dictionary:
	if slot < 0 and file_exists(SAVE_PATH % current_save_slot):
		slot = current_save_slot
	if slot < 0:
		for i: int in MAX_SAVE_SLOTS:
			if file_exists(SAVE_PATH % i):
				slot = i
				current_save_slot = i
	return read_file(SAVE_PATH % slot)

func read_file(path: String) -> Dictionary:
	path = add_steam_user_id(path)
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if !file:
		var error: Error = FileAccess.get_open_error()
		print("Failed to load file at \"%s\" (%d: %s)" % [path, error, error_string(error)])
		return {}


	var json: JSON = JSON.new()


	var json_string: String = file.get_as_text()
	var parse_result: Error = json.parse(json_string)
	if not parse_result == OK:
		print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
		return {}

	return json.get_data()

func save_user_data() -> void :
	var data: Dictionary = {}
	data[SAVE_SLOT] = current_save_slot
	AudioManager.save(data)
	Options.save(data)
	write_file(USER_SAVE_PATH, data)

func save_save_data() -> void :
	assert (current_save_slot >= 0, "You forgot to set the current slot")
	var data: Dictionary = {}
	GameManager.save(data)
	TechTree.save(data)
	TutorialManager.save(data)
	data["last_played"] = int(Time.get_unix_time_from_system())
	write_file(SAVE_PATH % current_save_slot, data)

func write_file(path: String, data: Dictionary) -> void :
	path = add_steam_user_id(path)

	if !DirAccess.dir_exists_absolute(path.get_base_dir()):
		DirAccess.make_dir_absolute(path.get_base_dir())

	var save_file: FileAccess = FileAccess.open(path, FileAccess.WRITE)

	var json_string: String = JSON.stringify(data, "", false)
	save_file.store_line(json_string)

func add_steam_user_id(path: String) -> String:
	if !OS.is_debug_build() and Steamy.has_steam:
		assert (Steamy.user_id != 0)
		var replacement: String = "user://%d/" % [Steamy.user_id]
		return path.replace("user://", replacement)
	return path

func has_save_slot_available() -> bool:
	for i: int in MAX_SAVE_SLOTS:
		if !file_exists(SAVE_PATH % i):
			return true
	return false

func start_new_game() -> void :
	for i: int in MAX_SAVE_SLOTS:
		if !file_exists(SAVE_PATH % i):
			current_save_slot = i
			save_user_data()
			return
	assert (false, "We should never get here!")

func file_exists(path: String) -> bool:
	path = add_steam_user_id(path)
	return FileAccess.file_exists(path)
