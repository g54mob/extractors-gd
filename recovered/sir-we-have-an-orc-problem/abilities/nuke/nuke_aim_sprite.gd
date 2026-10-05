extends Sprite2D


func _process(_delta: float) -> void :
	global_position = get_global_mouse_position()
	queue_redraw()

func _draw() -> void :
	draw_circle(Vector2.ZERO, Nuke.get_radius(), Color(1, 1, 1, 0.24), false, 3)
