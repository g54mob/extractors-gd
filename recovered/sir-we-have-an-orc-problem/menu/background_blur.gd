class_name BackgroundBlur extends Control

var blur_material: ShaderMaterial

func _ready() -> void :
	blur_material = $Blur.material

	visibility_changed.connect(on_visibility_changed)

func on_visibility_changed() -> void :

	if visible:
		set_blur_power(1.0)

func set_blur_power(val: float) -> void :
	blur_material.set_shader_parameter("blur_power", val)
