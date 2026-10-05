class_name UpgradeData extends Resource

enum ValueDisplayType{
	FLOAT, INT
}

@export var id: StringName
@export var name: String
@export var icon: Texture2D = null
@export var description: String
@export var value: float
@export var value_display_type: ValueDisplayType = ValueDisplayType.FLOAT
@export var max_level: int = 1
@export var currency: Currency.Type
@export var cost: int = 1
@export var cost_change: float = 2
@export var children: Array[UpgradeData] = []
@export var is_implemented: bool = true
@export var is_in_demo: bool = true

func is_unlockable() -> bool:
	return is_implemented and (is_in_demo or !(OS.has_feature("playtest") or OS.has_feature("demo")))

func get_cost_for_level(level: int) -> int:
	return roundi(cost * pow(cost_change, level))
