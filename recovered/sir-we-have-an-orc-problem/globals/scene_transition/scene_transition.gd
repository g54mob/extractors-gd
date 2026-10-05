extends Node

signal scene_change_started
signal fade_out_completed

var overlay: CanvasLayer
var fade: ColorRect
var skip_fade_arg: bool = false
var is_transitioning: bool = false

func initialize() -> void :
	process_mode = PROCESS_MODE_ALWAYS

	overlay = (load("res://globals/scene_transition/black_overlay.tscn") as PackedScene).instantiate()
	add_child(overlay)
	fade = overlay.get_child(0)

	overlay.visible = false
	var args: = OS.get_cmdline_args()
	for arg: String in args:
		if arg == "--skip-fade":
			skip_fade_arg = true
			break

func change_scene(path: String, skip_fade: bool = false) -> void :
	print("Changing scene to '%s'" % path)
	is_transitioning = true
	scene_change_started.emit()
	if skip_fade_arg or skip_fade:
		get_tree().change_scene_to_file(path)
		is_transitioning = false
		return

	overlay.visible = true

	fade.color.a = 0

	var tween: Tween = create_tween()
	tween.tween_property(fade, "color", Color.BLACK, 0.5)
	await tween.finished

	fade_out_completed.emit()

	get_tree().change_scene_to_file(path)

	tween = create_tween()
	tween.tween_property(fade, "color", Color(0, 0, 0, 0), 0.5)
	await tween.finished

	overlay.visible = false
	is_transitioning = false
