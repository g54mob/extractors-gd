extends CanvasLayer

const FADE_DURATION: float = 0.1

func make_visible(visible_in: bool) -> void :
	if visible_in == visible:
		return
	if !visible:
		visible = visible_in
		var fade_in: Tween = create_tween()
		fade_in.set_parallel(true)
		fade_in.tween_method( func(val: float) -> void :
			( %Blur.material as ShaderMaterial).set_shader_parameter("blur_power", val)
			, 0.0, 1.0, FADE_DURATION)
		%ContentContainer.modulate.a = 0.0
		fade_in.tween_property( %ContentContainer, "modulate:a", 1.0, FADE_DURATION)
	else:
		if SceneTransition.is_transitioning:
			return

		var fade_out: Tween = create_tween()
		fade_out.set_parallel(true)
		fade_out.tween_method( func(val: float) -> void :
			( %Blur.material as ShaderMaterial).set_shader_parameter("blur_power", val)
			, 1.0, 0.0, FADE_DURATION)
		fade_out.tween_property( %ContentContainer, "modulate:a", 0.0, FADE_DURATION)
		fade_out.chain()
		fade_out.tween_callback(set_visible.bind(false))
