extends VBoxContainer

const LEVEL_DIR: = "res://levels"

func _ready() -> void :
	var most_recent_unlocked_level: LevelPanel = null

	for level_id: int in GameManager.levels.keys():
		var level_panel: LevelPanel = load("res://tech_tree/hud/level_panel.tscn").instantiate()
		level_panel.level_id = level_id
		add_child(level_panel)
		if level_panel.is_unlocked:
			most_recent_unlocked_level = level_panel

	visibility_changed.connect(focus_newest_level.bind(most_recent_unlocked_level), CONNECT_ONE_SHOT)

func focus_newest_level(target: LevelPanel) -> void :
	await get_tree().create_timer(0.01).timeout
	var viewport_height: int = %ScrollContainer.size.y
	var target_center: float = target.position.y + target.size.y * 0.5
	var scroll_y: float = target_center - viewport_height * 0.5
	scroll_y = clamp(scroll_y, 0.0, %ScrollContainer.get_v_scroll_bar().max_value)

	%ScrollContainer.scroll_vertical = int(scroll_y)
