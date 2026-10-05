class_name NewGameDialog extends Control

signal yes_pressed(index: int)

var slot_index: int = 0

func _ready() -> void :
	%Label.text = tr("Are you sure you want to overwrite slot #{x} and start a new game?").format({"x": slot_index + 1})

func _on_no_button_pressed() -> void :
	queue_free()

func _on_yes_button_pressed() -> void :
	yes_pressed.emit(slot_index)
