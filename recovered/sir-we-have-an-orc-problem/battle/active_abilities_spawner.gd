extends Node2D

signal strafing_uses_decreased(uses_left: int)
signal nuke_uses_decreased(uses_left: int)

@export var missile_btn: Button
var missile_progress: TextureProgressBar

@export var cryo_beam_btn: Button
var cryo_beam_progress: TextureProgressBar

var battle: Battle
var cooldown_missile: float = 0.0
var missile_damage: float = 1.0
var missile_radius: float = 4.0

var missile_toggled_on: bool = false
var cryo_beam_toggled_on: bool = false
var cryo_beam_remaining_time: float = 10.0

func spawn_new_strafing_run() -> void :
	assert ( !active_strafing_run)
	active_strafing_run = load("res://abilities/strafing_run/strafing_run.tscn").instantiate()
	active_strafing_run.battle = battle
	add_child(active_strafing_run)
	active_strafing_run.placing = true
	active_strafing_run.start_pos = get_global_mouse_position()

var active_ability: int = 1:
	set(value):
		if value == active_ability:
			return
		if value != 1:
			missile_toggled_on = false
		if value != 3:
			finish_aiming_nuke()
		if active_ability == 2:
			if active_strafing_run:
				active_strafing_run.queue_free()
				active_strafing_run = null
		elif value == 2:
			spawn_new_strafing_run()
		if value == 3:
			start_aiming_nuke()
		if value != 4:
			cryo_beam_toggled_on = false
			%CryoBeamLine.visible = false
			%CryoBeamParticles.emitting = false
			fade_out_cryo_beam_sound()

		active_ability = value

var current_strafing_run: StrafingRun = null
var active_strafing_run: StrafingRun = null

var strafing_uses: = 0
var nuke_uses: = 0
var nuke_aim_sprite: Sprite2D

var cryo_beam_radius: float = 1.0
var cryo_beam_freeze_duration: float = 1.0

func _ready() -> void :
	battle = get_tree().get_first_node_in_group("battle")
	cooldown_missile = Missile.get_cooldown()
	strafing_uses = StrafingRun.get_uses()
	nuke_uses = Nuke.get_uses()

	cryo_beam_radius = CryoBeam.get_radius()
	cryo_beam_freeze_duration = CryoBeam.get_freeze_duration()
	cryo_beam_remaining_time = CryoBeam.get_fuel()

	missile_progress = missile_btn.get_node("TextureProgressBar")
	cryo_beam_progress = cryo_beam_btn.get_node("TextureProgressBar")
	cryo_beam_progress.max_value = cryo_beam_remaining_time


	set_process_unhandled_input(false)
	battle.phase_changed.connect(set_process_unhandled_input.unbind(1).bind(true), CONNECT_ONE_SHOT)
	battle.phase_changed.connect(check_for_battle_end)

func _physics_process(delta: float) -> void :
	if !battle.is_paused:
		if Missile.is_unlocked():
			cooldown_missile -= delta
			missile_progress.visible = cooldown_missile > 0.0
			missile_progress.value = clampf((Missile.get_cooldown() - cooldown_missile) / Missile.get_cooldown(), 0.0, 1.0)

	if missile_toggled_on and active_ability == 1:
		if cooldown_missile <= 0.0:
			cooldown_missile = Missile.get_cooldown()
			var target_pos: = get_global_mouse_position().clamp(Vector2.ZERO, battle.world_data.world_size)
			var size: Vector2 = get_viewport_rect().size / %Camera2D.zoom
			var rect: = Rect2( %Camera2D.global_position - size * 0.5, size)
			target_pos = target_pos.clamp(rect.position, rect.position + rect.size)
			var missile: Missile = load("res://abilities/missile/missile.tscn").instantiate()
			missile.battle = battle
			var vis_rect: = get_viewport().get_visible_rect()
			var half_height: float = vis_rect.size.y * 0.5 / %Camera2D.zoom.y
			missile.global_position = %Camera2D.global_position + Vector2(0.0, half_height)
			missile.target_pos = target_pos
			missile.explosion_damage = Missile.get_damage()
			missile.explosion_radius = Missile.get_radius()
			missile.time_to_target = 0.2
			missile.process_mode = Node.PROCESS_MODE_PAUSABLE
			add_child(missile)

			if TechTree.get_upgrade(&"missile_clickhold").level == 0:
				missile_toggled_on = false

	if cryo_beam_toggled_on and active_ability == 4:
		if cryo_beam_remaining_time > 0.0:
			if ! %CryoBeamLine.visible:
				%CryoBeamLine.visible = true
			cryo_beam_remaining_time -= delta
			cryo_beam_progress.value = cryo_beam_remaining_time
			var target_pos: = get_global_mouse_position().clamp(Vector2.ZERO, battle.world_data.world_size)
			var size: Vector2 = get_viewport_rect().size / %Camera2D.zoom
			var rect: = Rect2( %Camera2D.global_position - size * 0.5, size)
			target_pos = target_pos.clamp(rect.position, rect.position + rect.size)
			%CryoBeamLine.global_position = target_pos
			%CryoBeamParticles.global_position = target_pos
			var body: = Rigidbody.new(target_pos, Vector2.ZERO, cryo_beam_radius, 1.0, 0.0)
			body.lifetime = 0.0
			body.ch_slow_timer = cryo_beam_freeze_duration
			body.ch_damage_report_id = Constants.DAMAGE_REPORT_ID_CRYO_BEAM
			body.sensor_mask = Rigidbody.Layers.ENEMIES
			body.layer = Rigidbody.Layers.EFFECTS
			GPUSim.add_rigidbodies([body])
		else:
			if %CryoBeamLine.visible:
				%CryoBeamLine.visible = false
				%CryoBeamParticles.emitting = false
				fade_out_cryo_beam_sound()
				EventBus.last_use_shot.emit()

var time_at_placement: int
func _unhandled_input(event: InputEvent) -> void :
	if active_ability == 1:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			missile_toggled_on = !missile_toggled_on

	elif active_ability == 2:
		if !active_strafing_run:
			return

		if event is InputEventMouseButton and strafing_uses > 0:
			var mbtn: InputEventMouseButton = event
			if mbtn.button_index == MOUSE_BUTTON_LEFT:
				if mbtn.is_pressed() and active_strafing_run.placing:
					active_strafing_run.start_pos = get_global_mouse_position()
					active_strafing_run.dir = Vector2.RIGHT
					active_strafing_run.placing = false
					active_strafing_run.input_style = StrafingRun.InputStyle.NONE
					time_at_placement = Time.get_ticks_msec()
				elif mbtn.is_pressed() and active_strafing_run.input_style == StrafingRun.InputStyle.PRESS:
					finish_strafing_run_placement()
				elif mbtn.is_released() and !active_strafing_run.placing:
					if active_strafing_run.input_style == StrafingRun.InputStyle.NONE:
						active_strafing_run.input_style = StrafingRun.InputStyle.PRESS
					elif active_strafing_run.input_style == StrafingRun.InputStyle.RELEASE:
						finish_strafing_run_placement()

		elif event is InputEventMouseMotion:
			if active_strafing_run.placing:
				active_strafing_run.start_pos = get_global_mouse_position()
			else:
				if active_strafing_run.input_style == StrafingRun.InputStyle.NONE and Time.get_ticks_msec() > time_at_placement + 100:
					active_strafing_run.input_style = StrafingRun.InputStyle.RELEASE
				active_strafing_run.dir = (get_global_mouse_position() - active_strafing_run.start_pos).normalized()

	elif active_ability == 3:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed() and nuke_uses > 0:
			var target_pos: = get_global_mouse_position()
			var nuke: Nuke = load("res://abilities/nuke/nuke.tscn").instantiate()
			nuke.battle = battle
			var vis_rect: = get_viewport().get_visible_rect()
			var half_height: float = vis_rect.size.y * 0.5 / %Camera2D.zoom.y
			nuke.global_position = %Camera2D.global_position + Vector2(0.0, half_height)
			nuke.target_pos = target_pos
			nuke.explosion_damage = Nuke.get_damage()
			nuke.explosion_radius = Nuke.get_radius()
			nuke.time_to_target = 2.0
			nuke.process_mode = Node.PROCESS_MODE_PAUSABLE
			add_child(nuke)
			nuke_uses -= 1
			nuke_uses_decreased.emit(nuke_uses)

			if nuke_uses <= 0:
				EventBus.last_use_shot.emit()
				finish_aiming_nuke()

	elif active_ability == 4:
		if event is InputEventMouseButton:
			var mev: InputEventMouseButton = event
			if mev.button_index == MOUSE_BUTTON_LEFT:
				cryo_beam_toggled_on = mev.pressed
				%CryoBeamLine.visible = cryo_beam_toggled_on and cryo_beam_remaining_time > 0.0
				if %CryoBeamLine.visible:
					%CryoBeamLine.global_position = get_global_mouse_position()
					%CryoBeamParticles.emitting = true
					%CryoBeamParticles.global_position = get_global_mouse_position()
					if cryo_beam_sound_fader:
						cryo_beam_sound_fader.kill()
						cryo_beam_sound_fader = null
					%CryoBeamAudioPlayer.volume_db = 10.0
					%CryoBeamAudioPlayer.play()
				else:
					fade_out_cryo_beam_sound()
					%CryoBeamParticles.emitting = false

func finish_strafing_run_placement() -> void :
	active_strafing_run.dir = (get_global_mouse_position() - active_strafing_run.start_pos).normalized()
	if active_strafing_run.dir.is_equal_approx(Vector2.ZERO):
		active_strafing_run.dir = Vector2.RIGHT

	active_strafing_run.start()
	active_strafing_run.process_mode = Node.PROCESS_MODE_PAUSABLE
	if current_strafing_run:
		if current_strafing_run.waiting_to_start:
			current_strafing_run.queue_free()
		else:
			current_strafing_run.can_restart = false
	current_strafing_run = active_strafing_run
	active_strafing_run = null
	spawn_new_strafing_run()
	strafing_uses -= 1
	strafing_uses_decreased.emit(strafing_uses)

	if strafing_uses <= 0:
		EventBus.last_use_shot.emit()

func start_aiming_nuke() -> void :
	if nuke_aim_sprite or nuke_uses <= 0:
		return

	nuke_aim_sprite = preload("res://abilities/nuke/nuke_aim_sprite.tscn").instantiate()
	get_parent().add_child(nuke_aim_sprite)

func finish_aiming_nuke() -> void :
	if nuke_aim_sprite:
		nuke_aim_sprite.queue_free()

var cryo_beam_sound_fader: Tween = null
func fade_out_cryo_beam_sound() -> void :
	if cryo_beam_sound_fader:
		cryo_beam_sound_fader.kill()
		cryo_beam_sound_fader = null

	cryo_beam_sound_fader = create_tween()
	cryo_beam_sound_fader.tween_property( %CryoBeamAudioPlayer, "volume_db", -80.0, 2)
	cryo_beam_sound_fader.tween_callback( %CryoBeamAudioPlayer.stop)

func check_for_battle_end(new_phase: Battle.Phase) -> void :
	if new_phase == Battle.Phase.END:
		active_ability = 1
		set_process_unhandled_input(false)
