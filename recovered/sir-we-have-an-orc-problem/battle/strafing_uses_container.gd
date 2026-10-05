extends Node

func _ready() -> void :
	var uses: = StrafingRun.get_uses()
	for i: int in get_child_count():
		get_child(i).visible = i < uses

	%ActiveAbilitiesSpawner.strafing_uses_decreased.connect(on_uses_decreased)

func on_uses_decreased(uses_left: int) -> void :
	for i: int in get_child_count():
		if i >= uses_left:
			get_child(i).modulate = Color(0.4, 0.4, 0.4)
