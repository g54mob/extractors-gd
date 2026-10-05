extends CanvasLayer

func _ready() -> void :
	visible = Options.crt_effect_enabled
	Options.crt_effect_changed.connect(set_visible)
