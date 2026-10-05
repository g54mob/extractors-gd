class_name Upgrade

enum State{
	HIDDEN, 
	LOCKED, 
	UNAVAILABLE, 
	READY, 
	LEVELED, 

}

var data: UpgradeData
var state: State = State.HIDDEN
var level: int = 0
var children: Array[Upgrade] = []

var cost: int:
	get:
		var added: int = 0
		if data.currency == Currency.Type.UPGRADE_MARKS:
			added = GameManager.get_additional_cost()
		return data.get_cost_for_level(level) + added

var current_value: float:
	get:
		return data.value * level

func _init(data_in: UpgradeData, state_in: State, level_in: int) -> void :
	data = data_in
	state = state_in
	level = level_in

func add_child(child: Upgrade) -> void :
	children.append(child)
	update_minimum_child_state(child)

func change_state(new_state: State) -> void :


	if state == new_state or (state >= State.UNAVAILABLE and new_state < State.UNAVAILABLE):
		return

	state = new_state

	for cu: Upgrade in children:
		update_minimum_child_state(cu)

func update_minimum_child_state(child: Upgrade) -> void :
	match state:
		State.UNAVAILABLE:
			if child.state < State.HIDDEN:
				child.change_state(State.HIDDEN)
		State.READY:
			if child.state < State.LOCKED:
				child.change_state(State.LOCKED)
		State.LEVELED:
			if child.state < State.READY:
				child.change_state(State.READY)

func is_max_level() -> bool:
	return level >= data.max_level

func can_afford() -> bool:
	if state < State.READY:
		return false

	if is_max_level():
		return false

	return GameManager.currency_amounts[data.currency] >= cost

func can_buy() -> bool:
	return data.is_unlockable() and can_afford()

func buy() -> void :
	if !can_buy():
		return

	if GameManager.spend_currency(data.currency, cost):
		level += 1
		change_state(State.LEVELED)
		if data.id == "buy_pink":
			GameManager.earn_currency(Currency.Type.ALL_KILLED_CHALLENGE, 1)
		SaveSystem.save_save_data()
		TechTree.emit_upgrades_changed()


func sell() -> void :
	if state < State.READY:
		return

	if level == 0:
		return

	level -= 1
	GameManager.earn_currency(data.currency, cost)

	if level == 0:
		change_state(State.READY)
		for cu: Upgrade in children:
			cu.set_to_zero()
			cu.state = State.UNAVAILABLE

	SaveSystem.save_save_data()
	TechTree.emit_upgrades_changed()

func set_to_zero() -> void :
	if state < State.LEVELED:
		return

	while level > 0:
		level -= 1
		GameManager.earn_currency(data.currency, cost)
	for cu: Upgrade in children:
		cu.set_to_zero()
		cu.state = State.UNAVAILABLE
