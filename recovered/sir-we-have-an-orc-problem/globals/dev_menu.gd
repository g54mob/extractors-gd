extends PanelContainer

func _ready() -> void :
	visible = DevOptions.cheats_enabled

	%CanRefundUpgradesButton.set_pressed_no_signal(DevOptions.can_refund_upgrades)

func _on_gain_upgrade_marks_button_pressed(amount: int) -> void :
	GameManager.earn_currency(Currency.Type.UPGRADE_MARKS, amount)

func _on_gain_level_finished_button_pressed(amount: int) -> void :
	GameManager.earn_currency(Currency.Type.LEVEL_FINISHED, amount)

func _on_gain_all_killed_button_pressed(amount: int) -> void :
	GameManager.earn_currency(Currency.Type.ALL_KILLED_CHALLENGE, amount)

func _unhandled_input(event: InputEvent) -> void :
	if event is InputEventKey:
		if DevOptions.cheats_enabled and event.keycode == KEY_D and event.is_released():
			visible = !visible

func _on_can_refund_upgrades_button_toggled(toggled_on: bool) -> void :
	DevOptions.can_refund_upgrades = toggled_on

func _on_reset_achievements_pressed() -> void :
	if OS.has_feature("cheats"):
		Achievements.reset_stats_and_achievements()
