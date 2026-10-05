class_name BaseTower
extends Node2D

enum TowerKind{
	GUNNER, 
	CANNON, 
	MINIGUN_ROBOT, 
	MORTAR, 
	FLAMETHROWER, 
	TESLA_COIL, 
	GRENADE_LAUNCHER, 
	LASER
}

const TOWER_SCENES: Dictionary[TowerKind, String] = {
	BaseTower.TowerKind.GUNNER: "res://towers/gunner/gunner.tscn", 
	BaseTower.TowerKind.CANNON: "res://towers/cannon/cannon.tscn", 
	BaseTower.TowerKind.MINIGUN_ROBOT: "res://towers/minigun_robot/minigun_robot.tscn", 
	BaseTower.TowerKind.MORTAR: "res://towers/mortar/mortar.tscn", 
	BaseTower.TowerKind.FLAMETHROWER: "res://towers/flamethrower/flamethrower.tscn", 
	BaseTower.TowerKind.TESLA_COIL: "res://towers/tesla_coil/tesla_coil.tscn", 
	BaseTower.TowerKind.GRENADE_LAUNCHER: "res://towers/grenade_launcher/grenade_launcher.tscn", 
	BaseTower.TowerKind.LASER: "res://towers/laser/laser.tscn"
}

const TOWER_UNLOCK_UPGRADES: Dictionary[TowerKind, StringName] = {
	BaseTower.TowerKind.GUNNER: &"gunner_unlock", 
	BaseTower.TowerKind.CANNON: &"cannon_unlock", 
	BaseTower.TowerKind.MINIGUN_ROBOT: &"minigun_robot", 
	BaseTower.TowerKind.MORTAR: &"mortar_unlock", 
	BaseTower.TowerKind.FLAMETHROWER: &"flamethrower_unlock", 
	BaseTower.TowerKind.TESLA_COIL: &"tesla_coil_unlock", 
	BaseTower.TowerKind.GRENADE_LAUNCHER: &"grenade_launcher_unlock", 
	BaseTower.TowerKind.LASER: &"laser_unlock", 
}

static func is_tower_unlocked(tower_kind: TowerKind) -> bool:
	var key: StringName = TOWER_UNLOCK_UPGRADES.get(tower_kind, &"")
	if key.is_empty():
		return true
	var unlock_upgrade: Upgrade = TechTree.get_upgrade(key)
	if !unlock_upgrade or unlock_upgrade.level == 0:
		return false
	return true

const DEGREES_TO_RADIANS: float = PI / 180.0
enum EditMode{
	NORMAL, 
	MOVABLE, 
	PRESELECTED, 
	SELECTED, 
	EDIT_TARGET, 
	DECONSTRUCTING
}
enum InputStyle{
	NONE, 
	PRESS, 
	RELEASE
}

signal editing_finished()
signal constructed()
signal aborted()

@export var target: Area2D

var has_valid_placement: bool = true:
	set(value):
		has_valid_placement = value
		_update_modulate()

var was_constructed: bool = false
var edit_mode: EditMode = EditMode.NORMAL:
	set(value):
		var value_before: = edit_mode
		edit_mode = value

		var in_normal_mode: bool = edit_mode == EditMode.NORMAL
		process_mode = Node.PROCESS_MODE_PAUSABLE if in_normal_mode else Node.PROCESS_MODE_ALWAYS
		_update_modulate()
		if edit_mode != value_before:
			on_edit_mode_changed()
			if edit_mode == EditMode.NORMAL:
				editing_finished.emit()

func _update_modulate() -> void :
	if edit_mode == EditMode.DECONSTRUCTING:
		modulate = Color.RED
	elif !has_valid_placement:
		modulate = Color.ORANGE_RED
	elif edit_mode != EditMode.NORMAL:
		modulate = Color.AQUA
	else:
		modulate = Color.WHITE


var input_style: = InputStyle.NONE
var target_pos: Vector2 = Vector2.ZERO
var is_target_hovered: = false
var initial_edit_target_done: = false

var battle: Battle = null
@onready var build_area: Area2D = %BuildArea
func _ready() -> void :

	battle = get_tree().get_first_node_in_group("battle")
	assert (build_area, "Every tower needs to have a 'BuildArea' Area2D")
	build_area.process_mode = Node.PROCESS_MODE_ALWAYS
	build_area.mouse_entered.connect(_on_mouse_entered)
	build_area.mouse_exited.connect(_on_mouse_exited)

	build_area.input_event.connect(_on_build_area_input_event)

	battle.phase_changed.connect( func(new_phase: Battle.Phase) -> void :
		if new_phase == Battle.Phase.BATTLE:
			if edit_mode != EditMode.NORMAL:
				edit_mode = EditMode.NORMAL
			build_area.monitoring = false
			$MoveIndicatorSprite.visible = false
			build_area.mouse_entered.disconnect(_on_mouse_entered)
			build_area.mouse_exited.disconnect(_on_mouse_exited)
		, CONNECT_ONE_SHOT
	)

	if has_targeting(get_kind()):
		target.input_event.connect(_on_target_input_event)
		target.mouse_entered.connect(_on_target_mouse_entered)
		target.mouse_exited.connect(_on_target_mouse_exited)


func _physics_process(_delta: float) -> void :
	var valid_placement: bool = true
	var build_area_circle_shape: CircleShape2D = ((build_area.get_child(0) as CollisionShape2D).shape as CircleShape2D)
	assert (build_area_circle_shape)
	var pos: = build_area.global_position
	var radius: = build_area_circle_shape.radius * scale.x
	var ws: = battle.world_data.world_size
	valid_placement = valid_placement and (pos.x - radius > 0)
	valid_placement = valid_placement and (pos.x + radius < ws.x)
	valid_placement = valid_placement and (pos.y - radius > 0)
	valid_placement = valid_placement and (pos.y + radius < ws.y)
	if valid_placement:
		var img: = battle.world_data.sdf_image
		var img_size: = Vector2(img.get_size())
		var uv_offset: = 0.5 * WorldGen.WORLD_UNITS_PER_PIXEL
		var uv: Vector2 = Vector2(
			clampf((pos.x - uv_offset) / ws.x, 0.0, 1.0), 
			clampf((pos.y - uv_offset) / ws.y, 0.0, 1.0)
		)
		var uv_scaled: = uv * img_size
		var uv_i: Vector2i = Vector2i(floori(uv_scaled.x), floori(uv_scaled.y))
		var weights: = uv_scaled - Vector2(uv_i)
		var sample_tl: = img.get_pixelv(uv_i + Vector2i(0, 0)).r
		var sample_tr: = img.get_pixelv(uv_i + Vector2i(1, 0)).r if uv_i.x < img.get_width() - 1 else sample_tl
		var sample_bl: = img.get_pixelv(uv_i + Vector2i(0, 1)).r if uv_i.y < img.get_height() - 1 else sample_tl
		var sample_br: = img.get_pixelv(uv_i + Vector2i(1, 1)).r if uv_i.y < img.get_height() - 1 else sample_tr
		var value: = lerpf(lerpf(sample_tl, sample_tr, weights.x), lerpf(sample_bl, sample_br, weights.x), weights.y)
		value *= WorldGen.WORLD_UNITS_PER_PIXEL
		valid_placement = valid_placement and value + radius < 0.0
	for area: Area2D in build_area.get_overlapping_areas():
		if area.collision_layer == 2:
			valid_placement = false
			break
	if valid_placement != has_valid_placement:
		has_valid_placement = valid_placement


var is_hovered: bool = false
func _on_mouse_entered() -> void :
	is_hovered = true
	if edit_mode != EditMode.EDIT_TARGET:
		$MoveIndicatorSprite.visible = true

func _on_mouse_exited() -> void :
	is_hovered = false
	$MoveIndicatorSprite.visible = false
	if edit_mode == EditMode.DECONSTRUCTING:
		edit_mode = EditMode.NORMAL

func _exit_tree() -> void :
	if was_constructed:
		var kind: = get_kind()
		towers_built[kind] -= 1
		battle.remove_tower(self)

func construct() -> void :
	var kind: = get_kind()
	if !towers_built.has(kind):
		towers_built[kind] = 0
	towers_built[kind] += 1
	battle.add_tower(self)
	was_constructed = true
	constructed.emit()

func deconstruct(shift_pressed: bool = false) -> void :
	if shift_pressed:
		for node: Node in battle.get_node("TowerLayer/TowerPlacement").get_children():
			var tower: = node as BaseTower
			@warning_ignore("static_called_on_instance")
			if tower and tower.get_kind() == get_kind():
				tower.queue_free()
	else:
		queue_free()

static var towers_built: Dictionary[TowerKind, int] = {}

static func get_kind() -> TowerKind:
	return TowerKind.GUNNER

static func get_towers_built(kind: TowerKind) -> int:
	return towers_built.get(kind, 0)

static func get_tower_limit(kind: TowerKind) -> int:
	match kind:
		TowerKind.GUNNER: return Gunner.get_tower_limit(kind)
		TowerKind.CANNON: return Cannon.get_tower_limit(kind)
		TowerKind.MINIGUN_ROBOT: return MinigunRobot.get_tower_limit(kind)
		TowerKind.MORTAR: return Mortar.get_tower_limit(kind)
		TowerKind.FLAMETHROWER: return Flamethrower.get_tower_limit(kind)
		TowerKind.TESLA_COIL: return TeslaCoil.get_tower_limit(kind)
		TowerKind.GRENADE_LAUNCHER: return GrenadeLauncher.get_tower_limit(kind)
		TowerKind.LASER: return Laser.get_tower_limit(kind)
		_: return 0

static func get_icon(kind: TowerKind) -> Texture2D:
	match kind:
		TowerKind.GUNNER: return Gunner.get_icon(kind)
		TowerKind.CANNON: return Cannon.get_icon(kind)
		TowerKind.MINIGUN_ROBOT: return MinigunRobot.get_icon(kind)
		TowerKind.MORTAR: return Mortar.get_icon(kind)
		TowerKind.FLAMETHROWER: return Flamethrower.get_icon(kind)
		TowerKind.TESLA_COIL: return TeslaCoil.get_icon(kind)
		TowerKind.GRENADE_LAUNCHER: return GrenadeLauncher.get_icon(kind)
		TowerKind.LASER: return Laser.get_icon(kind)
		_: return null

static func has_targeting(kind: TowerKind) -> bool:
	if kind == TowerKind.TESLA_COIL:
		return false
	return true

static func _create_from_data(_data: Dictionary) -> BaseTower:
	return null

func save_to_data() -> Dictionary:
	return {}

static func create_from_data(data: Dictionary) -> BaseTower:
	var kind_string: String = data.get("kind", "")
	var index: int = TowerKind.keys().find(kind_string)
	if index < 0:
		return null
	var kind: TowerKind = TowerKind.values()[index]
	var tower: BaseTower = null
	match kind:
		TowerKind.GUNNER: tower = Gunner._create_from_data(data)
		TowerKind.CANNON: tower = Cannon._create_from_data(data)
		TowerKind.MINIGUN_ROBOT: tower = MinigunRobot._create_from_data(data)
		TowerKind.MORTAR: tower = Mortar._create_from_data(data)
		TowerKind.FLAMETHROWER: tower = Flamethrower._create_from_data(data)
		TowerKind.TESLA_COIL: tower = TeslaCoil._create_from_data(data)
		TowerKind.GRENADE_LAUNCHER: tower = GrenadeLauncher._create_from_data(data)
		TowerKind.LASER: tower = Laser._create_from_data(data)
		_: tower = null
	tower.edit_mode = EditMode.NORMAL
	return tower

var time_at_construction: int
func _unhandled_input(event: InputEvent) -> void :
	if edit_mode == EditMode.MOVABLE:
		if event is InputEventMouseMotion:
			global_position = get_global_mouse_position()
		elif event is InputEventMouseButton:
			if input_style == InputStyle.PRESS:
				if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed() and !event.is_echo():
					( func() -> void :
						if has_valid_placement:
							if was_constructed:
								edit_mode = EditMode.SELECTED
							else:
								time_at_construction = Time.get_ticks_msec()
								construct()
								if target_pos == Vector2.ZERO:
									target_pos = global_position
								edit_mode = EditMode.EDIT_TARGET if has_targeting(get_kind()) else EditMode.NORMAL
							input_style = InputStyle.NONE
						else:
							AudioManager.play_ui_sound(AudioManager.ui_wrong, 0.0, randf_range(0.9, 1.1))
					).call_deferred()
					get_viewport().set_input_as_handled()
				if event.button_index == MOUSE_BUTTON_RIGHT and event.is_released():
					queue_free()
					aborted.emit()
			elif input_style == InputStyle.RELEASE:
				if event.button_index == MOUSE_BUTTON_LEFT and event.is_released():
					( func() -> void :
						if has_valid_placement:
							edit_mode = EditMode.SELECTED
							input_style = InputStyle.NONE
						else:
							AudioManager.play_ui_sound(AudioManager.ui_wrong, 0.0, randf_range(0.9, 1.1))
							input_style = InputStyle.PRESS
					).call_deferred()
					get_viewport().set_input_as_handled()

	elif edit_mode == EditMode.EDIT_TARGET:
		if input_style == InputStyle.NONE:
			if event is InputEventMouseMotion and Time.get_ticks_msec() > time_at_construction + 250:
				input_style = InputStyle.RELEASE
			elif event is InputEventMouseButton:
				if event.button_index == MOUSE_BUTTON_LEFT and event.is_released():
					input_style = InputStyle.PRESS
					get_viewport().set_input_as_handled()
		else:
			if event is InputEventMouseButton:
				if event.button_index == MOUSE_BUTTON_LEFT and ((input_style == InputStyle.PRESS and event.is_pressed()) or (input_style == InputStyle.RELEASE and event.is_released())):
					if !initial_edit_target_done:
						edit_mode = EditMode.NORMAL
					else:
						edit_mode = EditMode.SELECTED
					initial_edit_target_done = true
					input_style = InputStyle.NONE
					get_viewport().set_input_as_handled()

				elif event.button_index == MOUSE_BUTTON_RIGHT and event.is_released() and !initial_edit_target_done:
					queue_free()
					aborted.emit()

	elif edit_mode == EditMode.DECONSTRUCTING:
		if (event is InputEventMouseMotion and event.relative != Vector2.ZERO) or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.is_released() and !is_hovered):
			edit_mode = EditMode.NORMAL

	elif edit_mode == EditMode.SELECTED:
		if event is InputEventMouseButton and !is_target_hovered and event.is_pressed() and (event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT):
			edit_mode = EditMode.NORMAL

func _on_build_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void :
	if battle.phase != Battle.Phase.BUILD:
		return
	if edit_mode == EditMode.NORMAL:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
				edit_mode = EditMode.PRESELECTED
				get_viewport().set_input_as_handled()
			if event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
				edit_mode = EditMode.DECONSTRUCTING
				get_viewport().set_input_as_handled()

	elif edit_mode == EditMode.PRESELECTED:
		if event is InputEventMouseMotion:
			edit_mode = EditMode.MOVABLE
			input_style = InputStyle.RELEASE
			get_viewport().set_input_as_handled()
		elif event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and event.is_released():
				edit_mode = EditMode.SELECTED
				input_style = InputStyle.PRESS
				get_viewport().set_input_as_handled()

	elif edit_mode == EditMode.DECONSTRUCTING:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_RIGHT and event.is_released():
				deconstruct(event.shift_pressed)
				get_viewport().set_input_as_handled()

	elif edit_mode == EditMode.SELECTED:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
				edit_mode = EditMode.MOVABLE
				input_style = InputStyle.RELEASE
				get_viewport().set_input_as_handled()

func _on_target_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void :
	if battle.phase != Battle.Phase.BUILD:
		return

	if edit_mode == EditMode.SELECTED:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
				edit_mode = EditMode.EDIT_TARGET if has_targeting(get_kind()) else EditMode.NORMAL
				input_style = InputStyle.RELEASE
				get_viewport().set_input_as_handled()

func on_edit_mode_changed() -> void :
	if has_targeting(get_kind()):
		target.visible = battle.phase == Battle.Phase.BUILD and (edit_mode == EditMode.SELECTED or edit_mode == EditMode.EDIT_TARGET or (edit_mode == EditMode.MOVABLE and was_constructed))
		target.global_position = target_pos

func _on_target_mouse_entered() -> void :
	is_target_hovered = true
	target.get_node("MoveIndicatorSprite").visible = true

func _on_target_mouse_exited() -> void :
	is_target_hovered = false
	target.get_node("MoveIndicatorSprite").visible = false

func clamp_target_pos(pos: Vector2) -> Vector2:
	var to_target: = pos - global_position
	var dir: = (to_target).normalized()
	var length: = to_target.length()
	if is_zero_approx(length):
		return target_pos
	if length < Constants.TARGET_MIN_DISTANCE:
		return global_position + dir * Constants.TARGET_MIN_DISTANCE
	if length < Constants.TARGET_MAX_DISTANCE:
		return pos
	return global_position + dir * Constants.TARGET_MAX_DISTANCE
