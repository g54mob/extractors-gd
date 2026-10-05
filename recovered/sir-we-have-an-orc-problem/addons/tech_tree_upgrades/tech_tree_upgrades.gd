@tool
extends EditorPlugin

const UPGRADE_PATH: = "res://tech_tree/upgrades/%s.tres"

var upgrades_exported: = 0

func _enter_tree() -> void :
	scene_saved.connect(on_scene_saved)

func on_scene_saved(path: String) -> void :
	if !path.contains("tech_tree.tscn"):
		return

	upgrades_exported = 0

	var tech_tree: Node2D = null
	var scene_roots: = EditorInterface.get_open_scene_roots()
	for sr: Node in scene_roots:
		if sr.name == "TechTree" and sr is Node2D:
			tech_tree = sr

	if !tech_tree:
		printerr("Could not find \"TechTree\" scene root node.")
		return

	var upgrades_parent: = tech_tree.get_node("Nodes")
	var first_upgrade: TechTreeNode = upgrades_parent.get_child(0)
	export_upgrade_from_node(first_upgrade)

	if upgrades_exported != upgrades_parent.get_child_count():
		printerr("Number of exported upgrades does not match number of TechTreeNodes in tech_tree.tscn. Are you missing child connections?")


func export_upgrade_from_node(node: TechTreeNode) -> void :
	for child: TechTreeNode in node.child_upgrades:
		export_upgrade_from_node(child)

	var upgrade: = UpgradeData.new()
	upgrade.id = node.upgrade_data.id
	upgrade.name = node.upgrade_data.name
	upgrade.description = node.upgrade_data.description
	upgrade.value = node.upgrade_data.value
	upgrade.value_display_type = node.upgrade_data.value_display_type
	upgrade.max_level = node.upgrade_data.max_level
	upgrade.currency = node.upgrade_data.currency
	upgrade.cost = node.upgrade_data.cost
	upgrade.cost_change = node.upgrade_data.cost_change
	upgrade.is_implemented = node.upgrade_data.is_implemented
	upgrade.is_in_demo = node.upgrade_data.is_in_demo
	for child: TechTreeNode in node.child_upgrades:
		var u: UpgradeData = load(UPGRADE_PATH % child.upgrade_data.id)
		upgrade.children.append(u)
	var error: = ResourceSaver.save(upgrade, UPGRADE_PATH % upgrade.id)
	if error != Error.OK:
		printerr("Failed to export UpgradeData \"%s\" to resource (%d: %s)" % [upgrade.name, error, error_string(error)])
	upgrades_exported += 1
