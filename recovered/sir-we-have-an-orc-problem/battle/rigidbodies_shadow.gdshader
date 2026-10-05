// NOTE: Shader automatically converted from Godot Engine 4.6.3.rc's CanvasItemMaterial.

shader_type canvas_item;
render_mode blend_mix;

uniform vec2 blur_scale;

void fragment() {
	vec2 uv = UV + vec2(2.0, -1.33) * blur_scale;
	float alpha = texture(TEXTURE, uv).a;
	COLOR = vec4(0.0, 0.0, 0.0, alpha * 0.75);
}
