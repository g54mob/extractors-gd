extends Node

var ui_player: AudioStreamPlayer = null
var ui_playback: AudioStreamPlaybackPolyphonic = null
var music_player: AudioStreamPlayer = null


var sfx_volume: float = 0.5:
	set(value):
		sfx_volume = value
		AudioServer.set_bus_volume_linear(AudioServer.get_bus_index(&"SFX"), sfx_volume)
var music_volume: float = 0.5:
	set(value):
		music_volume = value
		AudioServer.set_bus_volume_linear(AudioServer.get_bus_index(&"Music"), music_volume)

class AudioPlayerArray:
	var array: Array[AudioStreamPlayer2D] = []
var one_time_audio_players: Dictionary[AudioStream, AudioPlayerArray] = {}

var ui_click: AudioStream
var ui_success: AudioStream
var ui_wrong: AudioStream

var camera: Camera2D

func load_data(save_data: Dictionary) -> void :
	process_mode = Node.PROCESS_MODE_ALWAYS

	get_tree().scene_changed.connect( func() -> void : one_time_audio_players = {})

	ui_player = AudioStreamPlayer.new()
	ui_player.bus = &"SFX"
	add_child(ui_player)

	var polyphonic: = AudioStreamPolyphonic.new()
	polyphonic.polyphony = 16
	ui_player.stream = polyphonic
	ui_player.max_polyphony = polyphonic.polyphony
	ui_player.play()
	ui_playback = ui_player.get_stream_playback()
	assert (ui_playback != null)

	music_player = AudioStreamPlayer.new()
	music_player.bus = &"Music"
	add_child(music_player)








	for key: StringName in save_data.keys():
		self.set(key, save_data[key])

	ui_click = load("res://audio/sounds/click.wav")
	ui_success = load("res://audio/sounds/success.wav")
	ui_wrong = load("res://audio/sounds/wrong.wav")

func save(save_data: Dictionary) -> void :
	save_data[&"sfx_volume"] = sfx_volume
	save_data[&"music_volume"] = music_volume

var _stream_timeouts: Dictionary = {}
func _process(delta: float) -> void :
	var streams_to_remove: Array[AudioStream] = []
	for stream: AudioStream in _stream_timeouts:
		_stream_timeouts[stream] -= delta
		if _stream_timeouts[stream] < 0.0:
			streams_to_remove.append(stream)
	for stream: AudioStream in streams_to_remove:
		_stream_timeouts.erase(stream)

func play_ui_sound(stream: AudioStream, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void :
	ui_playback.play_stream(stream, 0.0, volume_db, pitch_scale)




func play_sound_at(stream: AudioStream, position: Vector2, volume_db: float = 0.0, pitch_scale: float = 1.0) -> AudioStreamPlayer2D:
	var array: AudioPlayerArray = one_time_audio_players.get(stream)
	if !array:
		array = AudioPlayerArray.new()
		array.array.resize(8)
		for i: int in array.array.size():
			var new_audio_player: = TowerAudioPlayer.new()
			new_audio_player.bus = &"Battle"
			new_audio_player.stream = stream
			get_tree().current_scene.add_child(new_audio_player)
			array.array[i] = new_audio_player
		one_time_audio_players[stream] = array

	var screen_center: = camera.global_position
	var max_sq_distance: = (position - screen_center).length_squared()
	var best_index: int = -1
	for i: int in array.array.size():
		var to_test: = array.array[i]
		if !to_test.playing:
			best_index = i
			break
		var sq_distance: = (to_test.global_position - screen_center).length_squared()
		if sq_distance > max_sq_distance:
			max_sq_distance = sq_distance
			best_index = i

	if best_index < 0:
		return null

	var audio_player: = array.array[best_index]
	audio_player.global_position = position
	audio_player.volume_db = volume_db
	audio_player.pitch_scale = pitch_scale
	audio_player.play()
	return audio_player

func play_music(stream: AudioStream) -> void :
	music_player.stream = stream
	music_player.play()
