shader_type canvas_item;
render_mode blend_mix;

uniform sampler2D arrow_tex: filter_linear_mipmap;
instance uniform vec2 world_size;


void fragment() {
	vec4 flow_in = texture(TEXTURE, UV);
	vec2 flow = normalize(flow_in.xy);
	ivec2 tex_size = textureSize(TEXTURE, 0);
	vec4 flow_color = vec4(flow.xy * 0.5 + 0.5, 0.0, 0.2);
	
	if (any(isnan(flow_in))) {
		COLOR = vec4(1.0, 0.0, 1.0, 1.0);
	}
	else if (flow_in.z > 0.0) {
		COLOR = vec4(0.0, 1.0, 0.0, 1.0);
	}
	else {
		vec2 uv_scaled = UV * vec2(tex_size);
		vec2 uv_fract = fract(uv_scaled);
		vec2 uv_nearest = (floor(uv_scaled) + 0.5) / vec2(tex_size);
		vec2 flow_nearest = normalize(texture(TEXTURE, uv_nearest).xy);
		float angle = atan(flow_nearest.y, flow_nearest.x);
		float s = sin(angle);
		float c = cos(angle);
		uv_fract -= 0.5;
		mat2 rot = mat2(vec2(c, -s),
						vec2(s,  c));
		uv_fract = rot * uv_fract;
		uv_fract += 0.5;
		vec4 arrow = texture(arrow_tex, uv_fract);
		COLOR = flow_color + arrow;
		COLOR.a *= step(0.5, max(abs(flow.x), abs(flow.y)));
	}
}
