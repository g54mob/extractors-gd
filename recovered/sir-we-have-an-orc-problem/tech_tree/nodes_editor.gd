@tool
extends Node2D

const NODE_DISTANCE: = 140

@export_tool_button("Recalculate Distances") var recalc_distances_button: Callable = recalculate_distances
@export_tool_button("Calculate costs") var calc_costs: Callable = calculate_costs

func _process(_delta: float) -> void :
	if Engine.is_editor_hint():
		queue_redraw()

func _draw() -> void :
	if !Engine.is_editor_hint():
		return
	for n: Node2D in get_children():
		var ttn: TechTreeNode = n as TechTreeNode
		if !ttn:
			continue

		for c: TechTreeNode in ttn.child_upgrades:
			draw_line(n.position, to_local(c.position), Color.WHITE, 3)

func recalculate_distances() -> void :
	for n: Node2D in get_children():
		var ttn: TechTreeNode = n as TechTreeNode
		if !ttn:
			continue

		for c: TechTreeNode in ttn.child_upgrades:
			var direction: = ttn.position.direction_to(c.position)
			c.position = ttn.position + direction * NODE_DISTANCE

func calculate_costs() -> void :
	var currencies: Dictionary[Currency.Type, Vector2i] = {
		Currency.Type.UPGRADE_MARKS: Vector2i.ZERO, 
		Currency.Type.LEVEL_FINISHED: Vector2i.ZERO, 
		Currency.Type.ALL_KILLED_CHALLENGE: Vector2i.ZERO
	}

	for n: Node2D in get_children():
		var ttn: TechTreeNode = n as TechTreeNode
		if !ttn:
			continue

		var upgrade_cost: int = 0
		for level: int in ttn.upgrade_data.max_level:
			upgrade_cost += roundi(ttn.upgrade_data.cost * pow(ttn.upgrade_data.cost_change, level))
		print("%s (%d): %d %s" % [
			ttn.upgrade_data.name, ttn.upgrade_data.max_level, 
			upgrade_cost, Currency.Type.keys()[ttn.upgrade_data.currency]])

		currencies[ttn.upgrade_data.currency] += Vector2i(1, upgrade_cost)

	print("----- TOTAL -----")
	for cur: Currency.Type in currencies:
		print("%d %s | total cost: %d" % [currencies[cur].x, Currency.Type.keys()[cur], currencies[cur].y])
