class_name SaveSlotSelection extends Control

@onready var slots_container: HBoxContainer = %SlotsContainer

var overwrite_mode: = false

func _ready() -> void :
	%OverwriteLabel.visible = overwrite_mode

	var all_saves_empty: bool = true
	for i: int in SaveSystem.MAX_SAVE_SLOTS:
		var save_data: Dictionary = SaveSystem.load_save_data(i)
		all_saves_empty = all_saves_empty && save_data.is_empty()

		var save_slot: SaveSlot = (load("res://menu/save_slot_selection/save_slot.tscn") as PackedScene).instantiate()
		save_slot.initialize(i, save_data)
		save_slot.pressed.connect(on_slot_pressed)
		if !overwrite_mode and (i == SaveSystem.current_save_slot or save_data.is_empty()):
			save_slot.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED
		slots_container.add_child(save_slot)
		if i < 2:
			var spacing: = Control.new()
			spacing.custom_minimum_size.x = 20
			slots_container.add_child(spacing)

	if all_saves_empty:
		%OverwriteLabel.text = tr("Choose a save slot")

func _on_back_button_pressed() -> void :
	queue_free()

func on_slot_pressed(index: int) -> void :
	if overwrite_mode:
		var save_slot: SaveSlot = slots_container.get_child(index * 2)
		if save_slot.data.is_empty():
			on_new_game_yes_pressed(index)
			return

		var ngd: NewGameDialog = (load("res://menu/save_slot_selection/new_game_dialog.tscn") as PackedScene).instantiate()
		ngd.slot_index = index
		ngd.yes_pressed.connect(on_new_game_yes_pressed)
		add_child(ngd)
	else:
		SaveSystem.current_save_slot = index
		var save_data: Dictionary = SaveSystem.load_save_data(index)
		GameManager.load_data(save_data)
		TechTree.load_data(save_data)
		TutorialManager.load_data(save_data)
		SceneTransition.fade_out_completed.connect(Menu.hide_menu, CONNECT_ONE_SHOT)
		SceneTransition.fade_out_completed.connect(queue_free, CONNECT_ONE_SHOT)
		SceneTransition.change_scene(Constants.TECH_TREE_SCENE_PATH)
		SaveSystem.save_user_data()

func on_new_game_yes_pressed(slot_index: int) -> void :
	AudioManager.play_ui_sound(Constants.new_game_boom)
	SceneTransition.fade_out_completed.connect(reset_progress.bind(slot_index), CONNECT_ONE_SHOT)
	GameManager.load_level(1)

func reset_progress(slot_index: int) -> void :
	queue_free()
	Menu.hide_menu()
	SaveSystem.current_save_slot = slot_index
	GameManager.load_data({})
	TechTree.load_data({})
	TutorialManager.load_data({})

	SaveSystem.save_user_data()
