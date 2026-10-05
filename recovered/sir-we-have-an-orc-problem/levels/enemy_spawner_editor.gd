@tool
class_name EnemySpawnerEditor
extends Node2D

@export var shape: Shape2D
@export var initial_velocity: Vector2 = Vector2.ZERO
@export var waves: Array[EnemySpawnWave] = []


func _process(_delta: float) -> void :
	queue_redraw()

func _draw() -> void :
	if shape is CircleShape2D:
		var cs: CircleShape2D = shape as CircleShape2D
		draw_circle(Vector2.ZERO, cs.radius, Color(0.851, 0.122, 0.792, 0.373))
	elif shape is RectangleShape2D:
		var rs: RectangleShape2D = shape as RectangleShape2D
		draw_rect(rs.get_rect(), Color(0.851, 0.122, 0.792, 0.373))
