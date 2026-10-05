extends CheckButton

func _on_toggled(toggled_on: bool) -> void :
	get_tree().paused = !toggled_on
