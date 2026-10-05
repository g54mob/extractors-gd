// NOTE: Shader automatically converted from Godot Engine 4.6.3.rc's CanvasItemMaterial.

shader_type canvas_item;
render_mode blend_mix;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;

uniform float blur_power: hint_range(0.0, 1.0);

void fragment() {
	COLOR = textureLod(screen_texture, UV, mix(0.0, 3.0, blur_power));
}
