class_name TechTreeHud
extends Control

signal play_pressed()

func _ready() -> void :
	get_tree().paused = false


	for c: Control in %StatsVBox.get_children():
		c.visible = false

	show_controls_container()

	TutorialManager.show_tech_tree_tutorial()
	var time_seconds: = roundi(GameManager.total_time_played)
	@warning_ignore_start("integer_division")
	var hours: = time_seconds / 3600
	var minutes: = (time_seconds % 3600) / 60
	var seconds: = time_seconds % 60
	@warning_ignore_restore("integer_division")
	%TotalTimePlayedLabel.text = "total_time_played: %02d:%02d:%02d" % [hours, minutes, seconds]
	%TotalUpgradeMarksSpent.text = "upgrade_marks_spent: %d (+%d)" % [GameManager.upgrade_marks_spent, GameManager.get_additional_cost()]
	GameManager.currency_changed.connect( func(_type: Currency.Type, _amount: int) -> void :
		%TotalUpgradeMarksSpent.text = "upgrade_marks_spent: %d (+%d)" % [GameManager.upgrade_marks_spent, GameManager.get_additional_cost()]
	)


func _on_play_button_pressed() -> void :
	if TutorialManager.get_child_count() > 0:

		return
	play_pressed.emit()
	TooltipManager.remove_all_tooltips()

func show_controls_container() -> void :
	%ControlsContainer.visible = Options.show_tech_tree_controls
	%ControlsButton.visible = !Options.show_tech_tree_controls

func _on_controls_button_pressed(visible_in: bool) -> void :
	Options.show_tech_tree_controls = visible_in
	SaveSystem.save_user_data()
	show_controls_container()
