extends TextureRect


func _process(_delta: float) -> void :
	var inv_tex_size: = Vector2.ONE / texture.get_size()
	(material as ShaderMaterial).set_shader_parameter("blur_scale", inv_tex_size * %Camera2D.zoom * 0.5)
