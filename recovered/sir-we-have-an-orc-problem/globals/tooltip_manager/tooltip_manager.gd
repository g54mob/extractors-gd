extends Node

var tooltip_layer: CanvasLayer = null
var tooltip_panel_scene: PackedScene = null

func initialize() -> void :
	process_mode = PROCESS_MODE_ALWAYS

	SceneTransition.scene_change_started.connect(remove_all_tooltips)
	SceneTransition.fade_out_completed.connect(remove_all_tooltips)

	tooltip_layer = CanvasLayer.new()
	tooltip_layer.layer = 10
	add_child(tooltip_layer)




	tooltip_panel_scene = load("res://globals/tooltip_manager/tooltip_panel.tscn")

func add_tooltip(source: Node, tooltip_content: Control, get_rect_func_in: Callable = (source as Control).get_global_rect, z_index_in: int = 100) -> Control:
	assert (tooltip_content)















	var tooltip: TooltipPanel = tooltip_panel_scene.instantiate()



	tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip.add_content(tooltip_content)
	tooltip.z_index = z_index_in

	tooltip_layer.add_child(tooltip)























































	var rect: Rect2 = get_rect_func_in.call() as Rect2
	set_initial_tooltip_position.call_deferred(tooltip, tooltip_content, rect)

	return tooltip

func set_initial_tooltip_position(tooltip: TooltipPanel, _tooltip_content: Control, parent_rect: Rect2) -> void :
	tooltip.position.x = parent_rect.position.x - 5 - tooltip.size.x * 0.5 + parent_rect.size.x * 0.5
	tooltip.position.y = parent_rect.position.y - tooltip.size.y - parent_rect.size.y * 1.5

	if tooltip.position.x < 0:
		tooltip.position.x = 1
	elif tooltip.position.x + tooltip.size.x > get_viewport().get_visible_rect().size.x:
		tooltip.position.x = get_viewport().get_visible_rect().size.x - tooltip.size.x - 1
	if tooltip.position.y < 0:
		tooltip.position.y = parent_rect.position.y + parent_rect.size.y * 2

func remove_all_tooltips() -> void :
	for c: Control in tooltip_layer.get_children():
		c.queue_free()
