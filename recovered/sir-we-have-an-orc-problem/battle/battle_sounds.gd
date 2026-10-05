class_name BattleSounds extends Node2D

static var Instance: BattleSounds = null

var camera: BattleCamera
var last_zoom: float
var current_max_distance: float = Constants.TOWER_AUDIO_RADIUS

func _ready() -> void :
	Instance = self
	camera = get_viewport().get_camera_2d()
	set_volume()

func _process(_delta: float) -> void :
	if !is_equal_approx(camera.zoom.x, last_zoom):
		set_volume()

func set_volume() -> void :
	last_zoom = camera.zoom.x

	var volume: float = 1.0
	volume = remap(last_zoom, camera.min_zoom, camera.max_zoom, 0.1, 1.0)
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index("Battle"), volume)

	var audio_players: Array = get_tree().get_nodes_in_group("zoom_audio")
	var distance_factor: float = remap(last_zoom, camera.min_zoom, camera.max_zoom, 3.0, 1.0)
	current_max_distance = Constants.TOWER_AUDIO_RADIUS * distance_factor
	for ap: AudioStreamPlayer2D in audio_players:
		ap.max_distance = current_max_distance
