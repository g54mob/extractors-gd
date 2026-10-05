@tool
class_name TechTreeNode extends Area2D

@onready var lock_sprite: Sprite2D = %LockTexture

@export var upgrade_data: UpgradeData
@export var child_upgrades: Array[TechTreeNode] = []
@export_tool_button("Update") var update_btn: Callable = update_in_editor
@export_tool_button("Cost preview") var cost_preview_btn: Callable = _on_cost_preview

func _on_cost_preview() -> void :
	for i: int in upgrade_data.max_level:
		print("Level %d: %d" % [i + 1, roundi(upgrade_data.cost * pow(upgrade_data.cost_change, i))])

var upgrade: Upgrade
var children: Array[TechTreeNode] = []
var lines: Array[Line2D] = []

var tooltip: Control

var base_color: Color
var pressed: = false

const NOT_AVAILABLE_COLOR: = Color("e3ea13")

func update_in_editor() -> void :
	%BackgroundSprite.modulate = Currency.COLORS[upgrade_data.currency]
	var is_unlockable: = upgrade_data.is_implemented and (upgrade_data.is_in_demo or !(OS.has_feature("playtest") or OS.has_feature("demo")))
	if !is_unlockable:
		%BackgroundSprite.modulate = NOT_AVAILABLE_COLOR
	%AffordableTexture.visible = false
	%LockTexture.visible = false
	%CrownTexture.visible = false
	%LevelLabel.text = "%d/%d" % [0, upgrade_data.max_level]
	if upgrade_data.icon:
		%IconSprite.texture = upgrade_data.icon

func _ready() -> void :
	if Engine.is_editor_hint():
		update_in_editor()
		property_list_changed.connect(update_in_editor)
		upgrade_data.property_list_changed.connect(update_in_editor)
		return
	z_index = Constants.TECH_TREE_NODE_Z_INDEX
	if upgrade_data.icon:
		%IconSprite.texture = upgrade_data.icon

	assert (upgrade_data, "Did you forget to assign one?")
	upgrade = TechTree.get_upgrade(upgrade_data.id)
	assert (upgrade)
	%AffordableTexture.texture = Currency.ICONS[upgrade_data.currency]
	%CrownTexture.visible = upgrade.is_max_level()
	base_color = Currency.COLORS[upgrade_data.currency]
	if !upgrade_data.is_unlockable():
		base_color = NOT_AVAILABLE_COLOR
	for child_upgrade: Upgrade in upgrade.children:
		for sibling: TechTreeNode in get_parent().get_children():
			if sibling.upgrade_data.id == child_upgrade.data.id:
				children.append(sibling)
				break

	for child: TechTreeNode in children:
		var line: = Line2D.new()
		line.z_index = -1
		line.width = 5
		line.antialiased = true
		line.gradient = Gradient.new()
		line.gradient.interpolation_color_space = Gradient.GRADIENT_COLOR_SPACE_OKLAB
		line.gradient.colors = [
			Color(base_color, 1.0), 
			Color(child.base_color, 1.0)]
		line.add_point(Vector2.ZERO)
		line.add_point(child.position - position)
		lines.append(line)
		add_child(line)

	TechTree.upgrades_changed.connect(update)
	GameManager.currency_changed.connect(_update_affordable)
	update.call_deferred()
	_update_affordable(upgrade_data.currency, 0)

var is_affordable: bool = false
func _update_affordable(_currency: Currency.Type, _amount: int) -> void :
	is_affordable = upgrade.can_afford()
	%AffordableTexture.visible = is_affordable and upgrade_data.is_unlockable()

func _process(_delta: float) -> void :
	var time: float = Time.get_ticks_msec() / 1000.0
	%AffordableTexture.rotation = time
	var cos_time: = cos(time * 4.0) + 1.0
	%AffordableTexture.scale = Vector2.ONE * (0.5 + 0.25 * cos_time)
	%LevelLabel.scale = Vector2.ONE * (1.0 if !(is_affordable and upgrade_data.is_unlockable()) else (1.0 + 0.1 * cos_time))

func _exit_tree() -> void :
	if tooltip:
		tooltip.queue_free()

var base_modulate: Color = Color.WHITE
func update() -> void :
	_update_affordable(upgrade_data.currency, 0)
	match upgrade.state:
		Upgrade.State.HIDDEN:
			visible = false
		Upgrade.State.LOCKED:
			visible = true
			base_modulate = base_color * 0.4
		Upgrade.State.UNAVAILABLE:
			visible = true
			lock_sprite.visible = false
			base_modulate = base_color * 0.7
		Upgrade.State.READY:
			visible = true
			lock_sprite.visible = false
			base_modulate = base_color * 1.0
		Upgrade.State.LEVELED:
			visible = true
			lock_sprite.visible = false
			base_modulate = base_color * (1.5 + 1.0 * (float(upgrade.level) / upgrade_data.max_level))

	%BackgroundSprite.modulate = Color(base_modulate, 1.0)
	%CrownTexture.visible = upgrade.is_max_level()
	%LevelLabel.text = "%d/%d" % [upgrade.level, upgrade_data.max_level]
	%LevelLabel.visible = upgrade.state >= Upgrade.State.READY and !upgrade.is_max_level()

	for i: int in children.size():
		children[i].update()
		lines[i].visible = upgrade.state >= Upgrade.State.UNAVAILABLE
		lines[i].gradient.set_color(0, Color(base_modulate, 1.0))
		lines[i].gradient.set_color(1, Color(children[i].base_modulate, 1.0))

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void :
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == MOUSE_BUTTON_LEFT and upgrade.can_buy():
				%Scalable.scale = Vector2.ONE * 1.4
				pressed = true
			return

		var level_before: = upgrade.level
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_released() and pressed:
			upgrade.buy()
			pressed = false
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.is_released() and DevOptions.can_refund_upgrades:
			upgrade.sell()
		else:
			return

		get_viewport().set_input_as_handled()

		_on_mouse_exited()
		_on_mouse_entered()

		%CrownTexture.visible = upgrade.is_max_level()

		if upgrade.level > level_before:
			if upgrade.is_max_level():
				AudioManager.play_ui_sound(AudioManager.ui_success, 0.0, randf_range(0.9, 1.1))
			else:
				AudioManager.play_ui_sound(AudioManager.ui_click, 0.0, randf_range(0.8, 1.0))
		elif upgrade.level < level_before:
			AudioManager.play_ui_sound(AudioManager.ui_click, 0.0, randf_range(1.1, 1.3))
		else:
			AudioManager.play_ui_sound(AudioManager.ui_wrong, 0.0, randf_range(0.9, 1.1))

func _on_mouse_entered() -> void :
	if upgrade.state < Upgrade.State.UNAVAILABLE:
		return

	%Scalable.scale = Vector2.ONE * 1.2
	var tooltip_content: UpgradeTooltip = Constants.upgrade_tooltip_scene.instantiate()
	tooltip_content.set_data(upgrade)
	tooltip = TooltipManager.add_tooltip(self, tooltip_content, func() -> Rect2:
		var shape: RectangleShape2D = $CollisionShape2D.shape
		return Rect2(get_viewport().get_canvas_transform() * (global_position - shape.size / 2), get_viewport().get_camera_2d().zoom * shape.size.x)
	)
	tooltip.self_modulate = base_color
	%BackgroundSprite.modulate = Color(base_modulate * 1.5, 1.0)


func _on_mouse_exited() -> void :
	if tooltip:
		tooltip.queue_free()
	%BackgroundSprite.modulate = Color(base_modulate, 1.0)
	%Scalable.scale = Vector2.ONE
	pressed = false
