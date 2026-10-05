extends VBoxContainer

@onready var currency_labels: Dictionary[Currency.Type, Label] = {
	Currency.Type.UPGRADE_MARKS: %UpgradeMarksLabel, 
	Currency.Type.LEVEL_FINISHED: %LevelFinishedMarksLabel, 
	Currency.Type.ALL_KILLED_CHALLENGE: %AllKilledMarksLabel, 
}

func _ready() -> void :
	for currency: Currency.Type in Currency.Type.values():
		currency_labels[currency].text = NumberFormatter.format(GameManager.currency_amounts[currency])
	GameManager.currency_changed.connect(on_currency_changed)

func on_currency_changed(type: Currency.Type, amount: int) -> void :
	currency_labels[type].text = NumberFormatter.format(amount)
