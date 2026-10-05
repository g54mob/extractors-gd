class_name SaveSlot extends PanelContainer

signal pressed(index: int)

var index: int = 0
var data: Dictionary

func initialize(index_in: int, data_in: Dictionary) -> void :
	index = index_in
	data = data_in

func _ready() -> void :
	if data.is_empty():
		%DataContainer.visible = false
		return

	%EmptyLabel.visible = false
	%Caption.text = tr("Slot #{x}").format({"x": index + 1})
	%CurrentLevelLabel.text = get_current_level()
	%MarksEarnedLabel.text = NumberFormatter.format(data.get("upgrade_marks_spent", 0) + data.get("UPGRADE_MARKS", 0))
	%LastPlayedLabel.text = NumberFormatter.format_date(data.get("last_played", 0))
	%ActiveLabel.visible = index == SaveSystem.current_save_slot

func _on_mouse_entered() -> void :
	scale = Vector2(1.05, 1.05)

func _on_mouse_exited() -> void :
	scale = Vector2.ONE

var pressed_down: bool = false
func _on_gui_input(event: InputEvent) -> void :
	if event is InputEventMouseButton:
		var btn_event: InputEventMouseButton = event
		if btn_event and btn_event.button_index == MOUSE_BUTTON_LEFT:
			if btn_event.pressed:
				pressed_down = true
			elif pressed_down and !btn_event.pressed and get_global_rect().has_point(get_global_mouse_position()):
				pressed.emit(index)

func get_current_level() -> String:
	var levels_dict: Dictionary = data.get("levels", {})
	var highest_level_unlocked: = 0
	for id: String in levels_dict.keys():
		var level_id: int = int(id)
		var level_dict: Dictionary = levels_dict.get(str(level_id), {})
		var survived: bool = level_dict.get("has_survived", false)
		if survived:
			if level_id > highest_level_unlocked:
				highest_level_unlocked = level_id

	if GameManager.levels.has(highest_level_unlocked + 1):
		highest_level_unlocked += 1

	return GameManager.levels[highest_level_unlocked].name.replace("Level ", "")
