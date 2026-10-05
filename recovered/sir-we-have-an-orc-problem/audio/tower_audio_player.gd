class_name TowerAudioPlayer extends AudioStreamPlayer2D

func _ready() -> void :
	add_to_group("zoom_audio")
	max_distance = BattleSounds.Instance.current_max_distance
