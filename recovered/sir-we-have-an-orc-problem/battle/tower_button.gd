class_name TowerButton
extends Button

var battle: Battle
@export var tower_kind: BaseTower.TowerKind = BaseTower.TowerKind.GUNNER
@onready var count_label: Label = %CountLabel


func _ready() -> void :
	if !BaseTower.is_tower_unlocked(tower_kind):
		visible = false
		return

	%ShortcutKeyLabel.text = shortcut.get_as_text()
	battle = get_tree().get_first_node_in_group("battle")
	battle.tower_added.connect(_on_tower_added)
	battle.tower_removed.connect(_on_tower_removed)
	icon = BaseTower.get_icon(tower_kind)

	update_state()

	pressed.connect(_on_pressed)

func update_state() -> void :
	disabled = BaseTower.get_towers_built(tower_kind) >= BaseTower.get_tower_limit(tower_kind)
	count_label.text = "%d/%d" % [BaseTower.get_towers_built(tower_kind), BaseTower.get_tower_limit(tower_kind)]

func _on_tower_added(_tower: BaseTower) -> void :
	update_state()

func _on_tower_removed(_tower: BaseTower) -> void :
	update_state()

func _on_pressed() -> void :
	%TowerPlacement.spawn_tower(tower_kind)
