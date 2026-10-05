class_name LevelData
extends Resource

@export var map_texture: Texture2D
@export var world_size: Vector2
@export var spawners: Array[EnemySpawnerData] = []
@export var sprite_sheet_texture: Texture2D
@export var wall_tiles_count: int = 1
@export var ground_tiles_count: int = 1
@export var enemy_health_buff: float
@export var level_bonus_marks: int = 0
@export var marks_upon_survival: int = 0
@export var marks_upon_all_killed: int = 0
