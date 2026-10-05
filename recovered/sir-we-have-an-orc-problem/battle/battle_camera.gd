class_name BattleCamera extends Camera2D

var is_moving_cam: bool = false
var target_zoom: Vector2 = Vector2.ONE

@export var zoom_speed: float = 0.1
@export var min_zoom: float = 0.1
@export var max_zoom: float = 10.0
@export var move_speed: float = 400
@export var edge_scroll_move_speed: float = 1
@export var edge_scroll_boost: float = 10

var viewport: Viewport
var limits: = Vector4(-2048, -2048, 2048, 2048)
var in_tech_tree: = false
var world_to_clip_mat: PackedFloat32Array = []

func _ready() -> void :
	Menu.instance.visibility_changed.connect(_on_menu_visibility_changed)
	viewport = get_viewport()
	in_tech_tree = get_tree().current_scene is not Battle
	if in_tech_tree:
		position = Options.tech_tree_camera_pos
		zoom = Vector2.ONE * Options.tech_tree_camera_zoom
		target_zoom = zoom

func _on_menu_visibility_changed() -> void :
	set_process( !Menu.instance.visible)
	set_process_unhandled_input( !Menu.instance.visible)

func _process(delta: float) -> void :
	if !is_equal_approx(zoom.x, target_zoom.x):
		var mouse_pos_before: = get_global_mouse_position()
		zoom += (target_zoom - zoom) * 0.1
		var mouse_pos_after: = get_global_mouse_position()
		position += mouse_pos_before - mouse_pos_after

	var movement: = Vector2.ZERO
	if Input.is_action_pressed("ui_up"):
		movement.y -= 1
	if Input.is_action_pressed("ui_down"):
		movement.y += 1
	if Input.is_action_pressed("ui_left"):
		movement.x -= 1
	if Input.is_action_pressed("ui_right"):
		movement.x += 1

	var boost_by_zoom: = remap(zoom.x, min_zoom, max_zoom, 2.0, 1.0)
	position += movement * move_speed * boost_by_zoom * delta

	if !is_moving_cam and Options.edge_scrolling:
		var boost_edge_by_zoom: = remap(zoom.x, min_zoom, max_zoom, edge_scroll_boost, 1.0)
		var mouse_pos: = viewport.get_mouse_position()
		if mouse_pos.x <= 0:
			position.x -= edge_scroll_move_speed * boost_edge_by_zoom
		elif mouse_pos.x >= viewport.get_visible_rect().size.x - 2:
			position.x += edge_scroll_move_speed * boost_edge_by_zoom
		if mouse_pos.y <= 0:
			position.y -= edge_scroll_move_speed * boost_edge_by_zoom
		elif mouse_pos.y >= viewport.get_visible_rect().size.y - 2:
			position.y += edge_scroll_move_speed * boost_edge_by_zoom

	if position.x < limits.x:
		position.x = limits.x
	elif position.x > limits.z:
		position.x = limits.z
	if position.y < limits.y:
		position.y = limits.y
	elif position.y > limits.w:
		position.y = limits.w

	if in_tech_tree:
		Options.tech_tree_camera_pos = position
		Options.tech_tree_camera_zoom = zoom.x

	force_update_transform()
	var vp_size: = viewport.get_visible_rect().size
	var proj: = Transform2D(
		Vector2(2.0 / vp_size.x, 0.0), 
		Vector2(0.0, 2.0 / vp_size.y), 
		Vector2(-1.0, -1.0)
	)

	var canvas: = get_canvas_transform()
	var world_to_clip: = proj * canvas
	world_to_clip_mat = PackedFloat32Array([
		world_to_clip.x.x, world_to_clip.x.y, 0.0, 0.0, 
		world_to_clip.y.x, world_to_clip.y.y, 0.0, 0.0, 
		0.0, 0.0, 1.0, 0.0, 
		world_to_clip.origin.x, world_to_clip.origin.y, 0.0, 1.0
	])

func _unhandled_input(event: InputEvent) -> void :
	if event is InputEventMouseButton:
		if event.is_released():
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				target_zoom *= (1.0 / (1.0 + zoom_speed))
				target_zoom = clamp(target_zoom, Vector2.ONE * min_zoom, Vector2.ONE * max_zoom)
			elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
				target_zoom *= (1.0 + zoom_speed)
				target_zoom = clamp(target_zoom, Vector2.ONE * min_zoom, Vector2.ONE * max_zoom)
		if event.button_index == MOUSE_BUTTON_RIGHT or event.button_index == MOUSE_BUTTON_MIDDLE or (event.button_index == MOUSE_BUTTON_LEFT and in_tech_tree):
			is_moving_cam = event.is_pressed()
	elif event is InputEventMouseMotion:
		if is_moving_cam:
			global_position -= event.screen_relative / zoom
