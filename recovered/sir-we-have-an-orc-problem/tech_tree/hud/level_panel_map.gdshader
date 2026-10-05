// NOTE: Shader automatically converted from Godot Engine 4.6.3.rc's CanvasItemMaterial.

shader_type canvas_item;
render_mode blend_mix;

uniform sampler2D tilemap: filter_nearest;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	if (tex.b > 0.5) {
		COLOR = textureLod(tilemap, vec2(0.25, 0.25) + vec2(0.5) * 0.25, 4);
	}
	else {
		COLOR = textureLod(tilemap, vec2(0.75, 0.75) + vec2(0.5) * 0.25, 4);
	}
}