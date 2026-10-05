class_name Menu extends Control

static var instance: Menu = null

static func initialize() -> void :
	var canvas_layer: = CanvasLayer.new()
	canvas_layer.layer = 4096
	var scene_tree: SceneTree = Engine.get_main_loop()
	scene_tree.root.add_child.call_deferred(canvas_layer)

	instance = (load("res://menu/menu.tscn") as PackedScene).instantiate()
	canvas_layer.add_child.call_deferred(instance)
	instance.visible = false

static func show_menu(is_startup: bool = false, has_save_file: bool = true) -> void :
	if !instance.visible:

		instance.show_instance(is_startup, has_save_file)

static func hide_menu() -> void :
	instance.hide_instance()

var background_blur: BackgroundBlur
var pause_state_before: bool = false

func _ready() -> void :
	background_blur = $BackgroundBlur

	%VersionLabel.text = "Version %s" % ProjectSettings.get_setting_with_override("application/config/version") as String

	if !OS.has_feature("demo") and !OS.has_feature("playtest"):
		%WishlistButton.visible = false
		%PressKitButton.visible = false
		var spacing: Control = Control.new()
		spacing.custom_minimum_size.y = 200
		%WishlistButton.get_parent().add_child(spacing)
		%WishlistButton.get_parent().move_child(spacing, 0)

func show_instance(is_startup: bool = false, has_save_file: bool = true) -> void :
	if is_startup:
		%Resume.visible = false
		if !has_save_file:
			%Continue.visible = false
	else:
		%Continue.visible = false
		%Resume.visible = true

	var current_scene: Node = get_tree().current_scene
	var is_battle: = current_scene is Battle
	%Surrender.visible = is_battle and TutorialManager.has_finished_tutorial
	%NewGame.visible = !is_battle
	%LoadGame.visible = !is_battle
	%LoadGame.disabled = SaveSystem.current_save_slot < 0
	if is_battle:
		var battle: Battle = current_scene
		pause_state_before = battle.is_paused
		battle.set_pause(true)
	else:
		pause_state_before = get_tree().paused
		get_tree().paused = true

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	visible = true

func hide_instance() -> void :
	visible = false
	var current_scene: Node = get_tree().current_scene
	if current_scene is Battle:
		(current_scene as Battle).set_pause(pause_state_before)
	else:
		get_tree().paused = pause_state_before

	if Options.edge_scrolling:
		Input.mouse_mode = Input.MOUSE_MODE_CONFINED

func _on_continue_pressed() -> void :
	slow_hide()

func _on_resume_pressed() -> void :
	hide_menu()

func _on_new_game_pressed() -> void :

















	_on_load_game_pressed(true)

func _on_options_pressed() -> void :
	var options: Control = (load("res://options/options_menu.tscn") as PackedScene).instantiate()
	add_child(options)

func _on_quit_pressed() -> void :
	if OS.has_feature("demo") or OS.has_feature("playtest"):
		var quit_popup: Control = load("res://menu/quit_popup.tscn").instantiate()
		add_child(quit_popup)
	else:
		get_tree().quit()

func _on_wishlist_button_pressed() -> void :
	Steamy.wishlist("main_menu")

func _on_discord_button_pressed() -> void :
	OS.shell_open("https://mumpitzgames.com/discord")

func _on_press_kit_button_pressed() -> void :
	OS.shell_open("https://drive.google.com/drive/folders/1KL6l3zLAsjJpPEZlS5iWuEpqhxE_bOey?usp=drive_link")

const FADE_DURATION: float = 0.5
func slow_hide() -> void :
	var fade_in: Tween = create_tween()
	fade_in.set_parallel(true)
	fade_in.tween_method(background_blur.set_blur_power, 1.0, 0.0, FADE_DURATION)
	fade_in.tween_property(self, "modulate:a", 0.0, FADE_DURATION)
	fade_in.finished.connect( func() -> void :
		hide_menu()
		modulate.a = 1.0
		background_blur.set_blur_power(1.0)
	)

func _on_surrender_pressed() -> void :
	if (get_tree().current_scene as Battle).phase == Battle.Phase.BATTLE:
		hide_menu()
		(get_tree().current_scene as Battle)._end_battle(true)
	else:
		GPUSim.stop()
		Engine.time_scale = 1.0

		(get_tree().current_scene as Battle).write_towers_to_level_progress()
		SaveSystem.save_save_data()

		SceneTransition.fade_out_completed.connect(hide, CONNECT_ONE_SHOT)
		SceneTransition.change_scene(Constants.TECH_TREE_SCENE_PATH)

func _on_load_game_pressed(overwrite_mode: bool = false) -> void :
	var save_slot_selection: SaveSlotSelection = (load("res://menu/save_slot_selection/save_slot_selection.tscn") as PackedScene).instantiate()
	save_slot_selection.overwrite_mode = overwrite_mode
	add_child(save_slot_selection)
