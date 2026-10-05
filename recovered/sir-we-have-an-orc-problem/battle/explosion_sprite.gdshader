// NOTE: Shader automatically converted from Godot Engine 4.6.2.rc's CanvasItemMaterial.

shader_type canvas_item;
render_mode blend_mix;

uniform vec4 color : source_color;
instance uniform float life_time_factor = 0.0;

void fragment() {
	vec2 delta = (UV - vec2(0.5)) * 2.0;
	float d2 = dot(delta, delta);
	float radius = 1.0 - abs(life_time_factor * 2.0 - 1.0);
	float f = d2 / radius;
	if (f > 1.0) {
		discard;
	}
	float inner_circle = 1.0; //smoothstep(life_time_factor * 0.5, life_time_factor, f);
	float a = inner_circle * (1.0 - f) * (1.0 - life_time_factor);
	COLOR = vec4(color.rgb, a);
}