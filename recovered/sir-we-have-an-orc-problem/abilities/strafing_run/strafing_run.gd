class_name StrafingRun
extends Node2D

enum InputStyle{
	NONE, 
	PRESS, 
	RELEASE
}

signal started

var start_pos: Vector2:
	set(value):
		start_pos = value
		_update_visuals()
var dir: Vector2:
	set(value):
		dir = value
		_update_visuals()
var width: float = 20.0
var length: float = 200.0
var can_restart: bool = false
var input_style: = InputStyle.NONE

const BASE_BULLET_COUNT: int = 55
const BASE_WIDTH: float = 50.0
const BASE_LENGTH: float = 200.0
const LENGTH_PER_LEVEL: float = 33.0
const BASE_EXPLOSION_DAMAGE: float = 22.0
const BASE_EXPLOSION_RADIUS: float = 14.0

var placing: bool = true:
	set(value):
		placing = value
		%Line2D.visible = !placing
		_update_visuals()

var waiting_to_start: bool = true

static func is_unlocked() -> bool:
	return TechTree.get_upgrade(&"strafing_run_unlock").level > 0

static func get_bullet_count() -> int:
	return (BASE_BULLET_COUNT
		+ roundi(TechTree.get_upgrade(&"strafing_run_bullet_count").current_value))

static func get_width() -> float:
	return (BASE_WIDTH
		+ TechTree.get_upgrade(&"strafing_run_width").current_value)

static func get_damage() -> float:
	return (BASE_EXPLOSION_DAMAGE
		+ TechTree.get_upgrade(&"strafing_run_damage").current_value
		+ TechTree.get_upgrade(&"strafing_run_damage_2").current_value)

static func get_radius() -> float:
	return (BASE_EXPLOSION_RADIUS
		+ TechTree.get_upgrade(&"strafing_run_radius").current_value)

static func get_uses() -> int:
	return roundi(1
		+ TechTree.get_upgrade(&"strafing_run_count").current_value
	)

static func get_length() -> float:
	return (BASE_LENGTH
		+ TechTree.get_upgrade(&"strafing_run_width").level * LENGTH_PER_LEVEL)

var battle: Battle
var planes: Array[StrafingRunPlane]

func _ready() -> void :
	width = get_width()
	length = get_length()

func start(cooldown_delay: float = 0) -> void :
	if cooldown_delay > 0:
		await get_tree().create_timer(cooldown_delay, false).timeout
	waiting_to_start = false
	started.emit()

	var plane: StrafingRunPlane = null
	for p: StrafingRunPlane in planes:
		if p.can_start:
			plane = p
			break
	if !plane:
		plane = Constants.strafing_run_plane_scene.instantiate()
		plane.initialize(start_pos, dir, length, width, battle)
		plane.shooting_done.connect(on_plane_shooting_done)
		plane.finished.connect(on_plane_finished)
		planes.append(plane)
		add_child(plane)
	plane.start()

	%Line2D.modulate.a = 0.5





func on_plane_shooting_done() -> void :
	if !can_restart:
		%Line2D.visible = false
		%Icon.visible = false


func on_plane_finished() -> void :
	var any_plane_visible: = false
	for p: StrafingRunPlane in planes:
		if p.visible:
			any_plane_visible = true
	if !can_restart and !any_plane_visible:
		queue_free()


func restart() -> void :
	if !can_restart:
		return
	start()


func _update_visuals() -> void :
	var offset_len: = length * 0.05
	%Line2D.points[0] = Vector2.ZERO
	%Line2D.points[1] = Vector2( - offset_len, - width * 0.5)
	%Line2D.points[2] = Vector2(length - offset_len, - width * 0.5)
	%Line2D.points[3] = Vector2(length, 0.0)
	%Line2D.points[4] = Vector2(length - offset_len, width * 0.5)
	%Line2D.points[5] = Vector2( - offset_len, width * 0.5)
	%Line2D.global_position = start_pos
	%Line2D.global_rotation = dir.angle()
	if placing:
		%Icon.global_position = start_pos
		%Icon.global_rotation = 0.0
	else:
		%Icon.global_position = start_pos + dir * length * 0.5
		%Icon.global_rotation = dir.angle()
