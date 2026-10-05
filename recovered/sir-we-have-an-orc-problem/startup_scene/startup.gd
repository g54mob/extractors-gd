extends Control

func _ready() -> void :
	Constants.initialize()

	var user_data: Dictionary = SaveSystem.load_user_data()
	AudioManager.load_data(user_data)
	Options.load_data(user_data)

	var save_data: Dictionary = SaveSystem.load_save_data()
	var has_save_file: bool = !save_data.is_empty()

	GameManager.load_data(save_data)
	TechTree.load_data(save_data)
	TutorialManager.load_data(save_data)
	GPUSim.initialize()
	TooltipManager.initialize()
	SceneTransition.initialize()

	Menu.initialize()

	var show_menu: = true
	var args: = OS.get_cmdline_args()
	for arg: String in args:
		if arg == "--skip-menu":
			show_menu = false

	if show_menu:

		var tween: = create_tween()
		%LoadingProgressBar.value = 1.0
		tween.tween_property( %LoadingProgressBar, "value", 100.0, 1.0)
		await tween.finished
		get_tree().scene_changed.connect(Menu.show_menu.bind(true, has_save_file), CONNECT_ONE_SHOT)

	var skip_fade: = !show_menu
	SceneTransition.change_scene.call_deferred(Constants.TECH_TREE_SCENE_PATH, skip_fade)

	AudioManager.play_music(Constants.music)
