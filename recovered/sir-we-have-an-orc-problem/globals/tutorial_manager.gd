extends Node

var has_finished_tutorial: bool = false

var showing_battle_tutorial_2: bool = false

func load_data(data: Dictionary) -> void :
	showing_battle_tutorial_2 = false
	has_finished_tutorial = data.get("has_finished_tutorial", false)

func save(data: Dictionary) -> void :
	data["has_finished_tutorial"] = has_finished_tutorial

func show_battle_tutorial() -> void :
	if TutorialManager.has_finished_tutorial:
		return

	if TechTree.get_upgrade(Constants.STARTING_UPGRADE_NAME).level == 0:
		var tutorial: Node = (load("res://tutorial/battle_tutorial_1.tscn") as PackedScene).instantiate()
		add_child(tutorial)
		(get_tree().current_scene as Battle).phase_changed.connect(
			tutorial.queue_free.unbind(1), 
			CONNECT_ONE_SHOT
		)
		SceneTransition.fade_out_completed.connect(
			tutorial.queue_free, 
			CONNECT_ONE_SHOT
		)
	else:
		showing_battle_tutorial_2 = true
		var tutorial: Node = (load("res://tutorial/battle_tutorial_2.tscn") as PackedScene).instantiate()
		add_child(tutorial)
		(get_tree().current_scene as Battle).phase_changed.connect(
			func(_new_phase: Battle.Phase) -> void :
				tutorial.queue_free()
				has_finished_tutorial = true
				SaveSystem.save_user_data(), 
			CONNECT_ONE_SHOT
		)
		SceneTransition.fade_out_completed.connect(
			tutorial.queue_free, 
			CONNECT_ONE_SHOT
		)

func show_tech_tree_tutorial() -> void :
	if TutorialManager.has_finished_tutorial or TechTree.get_upgrade(Constants.STARTING_UPGRADE_NAME).level > 0 or GameManager.currency_amounts[Currency.Type.UPGRADE_MARKS] == 0:
		return

	var tutorial: Node = (load("res://tutorial/tech_tree_tutorial.tscn") as PackedScene).instantiate()
	add_child(tutorial)
	TechTree.upgrades_changed.connect(tutorial.queue_free, CONNECT_ONE_SHOT)
	SceneTransition.fade_out_completed.connect(tutorial.queue_free, CONNECT_ONE_SHOT)
