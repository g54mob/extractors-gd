// NOTE: Shader automatically converted from Godot Engine 4.6.2.rc's CanvasItemMaterial.

shader_type canvas_item;
render_mode blend_mix;

uniform vec2 world_size = vec2(2048.0, 2048.0);
uniform float sdf_scale = 8.0;
uniform float sim_time = 10.0;
uniform int wall_tiles_count = 1;
uniform int ground_tiles_count = 1;
uniform vec3 fire_color = vec3(3.5, 2.0, 0.1);
uniform sampler2D sdf_nearest : filter_nearest;
uniform sampler2D sdf_linear : filter_linear;
uniform sampler2D sprite_sheet_tex : filter_nearest_mipmap, source_color;
uniform sampler2D corpses_tex: filter_nearest, source_color;
uniform sampler2D fire_tex: filter_nearest, source_color;
uniform sampler2D flow_tex : filter_linear;

const bool USE_SHADOW = true;
const vec2 LIGHT_DIR = normalize(vec2(-3.0, 2.0));
const float SHADOW_LENGTH = 3.0;


const ivec2 WALL_TILE_INDICES[] = {
	ivec2(1, 1),
	ivec2(0, 3),
	ivec2(1, 3),
	ivec2(2, 3)
};

const ivec2 GROUND_TILE_INDICES[] = {
	ivec2(3, 3),
	ivec2(3, 2),
	ivec2(3, 1),
	ivec2(3, 0)
};

float sdf(sampler2D tex, vec2 uv) {
    return sdf_scale * texture(tex, uv).r;
}

vec2 sdf_gradient(sampler2D tex, vec2 uv, vec2 eps) {
    float dx = sdf(tex, uv + vec2(eps.x, 0.0)) - sdf(tex, uv - vec2(eps.x, 0.0));
    float dy = sdf(tex, uv + vec2(0.0, eps.y)) - sdf(tex, uv - vec2(0.0, eps.y));

    return vec2(dx, dy) / (2.0 * eps);
}

float hash(uint x) {
    x ^= x >> 16u;
    x *= 0x7feb352du;
    x ^= x >> 15u;
    x *= 0x846ca68bu;
    x ^= x >> 16u;
    return float(x) / 4294967295.0;
}


void fragment() {
	vec2 offset = TEXTURE_PIXEL_SIZE * 0.5;
	vec2 sdf_uv = UV - TEXTURE_PIXEL_SIZE * 0.5;
	float tl = step(-0.1, texture(sdf_nearest, UV + offset * vec2(-1.0, -1.0)).r);
	float tr = step(-0.1, texture(sdf_nearest, UV + offset * vec2( 1.0, -1.0)).r);
	float bl = step(-0.1, texture(sdf_nearest, UV + offset * vec2(-1.0,  1.0)).r);
	float br = step(-0.1, texture(sdf_nearest, UV + offset * vec2( 1.0,  1.0)).r);
	float sum = tl + tr + bl + br;
	float sprite_step = 1.0 / 4.0;
	
	vec2 pixel_size = 1.0 / TEXTURE_PIXEL_SIZE;
	vec2 inner_real_uv = fract(UV / TEXTURE_PIXEL_SIZE);
	vec2 scaled_uv = sdf_uv / TEXTURE_PIXEL_SIZE;
	ivec2 tile = ivec2(scaled_uv);
	vec2 inner_uv = fract(scaled_uv);
	float is_wall = 0.0;
	float tile_random = hash(uint(tile.x * tile.y));
	ivec2 sprite_index = GROUND_TILE_INDICES[int(round(tile_random * float(ground_tiles_count) - 0.5))];
	if (sum <= 1.0) {
		sprite_index = WALL_TILE_INDICES[int(round(tile_random * float(wall_tiles_count) - 0.5))];
		is_wall = 1.0;
	}
	vec2 sprite_offset = vec2(sprite_index) * sprite_step;
	vec2 sprite_uv = sprite_offset + inner_uv * sprite_step;
	vec4 ground = vec4(vec3(0.0), 1.0);
	vec2 texSize = vec2(textureSize(sprite_sheet_tex, 0));
	vec2 dx = dFdx(scaled_uv * texSize);
	vec2 dy = dFdy(scaled_uv * texSize);
	float rho = max(dot(dx, dx), dot(dy, dy));
	float lod = 0.25 * log2(rho);
	ground = textureLod(sprite_sheet_tex, sprite_uv, lod);
	ground.a = 1.0;
	
	if (sum >= 2.0 && sum < 4.0) {
		ivec2 index = ivec2(1, 1);
		
		float t = tl + tr;
		float b = bl + br;
		float r = tr + br;
		float l = tl + bl;
		if (sum >= 1.9 && sum < 2.1) {
			if (r > 1.0) index = ivec2(2, 1);
			else if (b > 1.0) index = ivec2(1, 2);
			else if (l > 1.0) index = ivec2(0, 1);
			else if (t > 1.0) index = ivec2(1, 0);
		}
		else if (sum >= 2.9) {
			if (tl == 0.0) index = ivec2(2, 2);
			else if (tr == 0.0) index = ivec2(0, 2);
			else if (br == 0.0) index = ivec2(0, 0);
			else if (bl == 0.0) index = ivec2(2, 0);
			else index = ivec2(1, 1);
		}
		
		vec2 dir_sprite_offset = vec2(index) * sprite_step;
		vec2 dir_sprite_uv = dir_sprite_offset + inner_uv * sprite_step;
		vec4 top_color = textureLod(sprite_sheet_tex, dir_sprite_uv, lod);
		ground = mix(ground, top_color, top_color.a);
		is_wall = step(0.1, top_color.a);
	}
	
	float is_ground = (1.0 - is_wall);
	vec4 corpses_color = texture(corpses_tex, UV);
	float fire_time = texture(fire_tex, UV).r;
	float noise = max(max(ground.r, ground.g), ground.b);
	float fire_time_offset = noise;
	float time_sine = sin(sim_time + noise);
	float fire_diff = sim_time - (fire_time - fire_time_offset);
	ground.rgb = mix(ground.rgb, corpses_color.rgb, corpses_color.a * is_ground);
	ground.rgb = mix(ground.rgb, vec3(0.0, 0.0, 0.0), (1.0 - smoothstep(0.0, 10.0, fire_diff)) * 0.8 * is_ground);
	float shadow_factor = 1.0;
	if (USE_SHADOW) {
		//float value = sdf(sdf_linear, UV);
		vec2 inv_world_size = TEXTURE_PIXEL_SIZE * 0.125;
		vec2 offset = UV - LIGHT_DIR * SHADOW_LENGTH * inv_world_size;
		float offset_value = sdf(sdf_linear, offset);
		bool is_offset_in_wall = offset_value <= 0.0;
		shadow_factor = mix(0.5, 1.0, is_offset_in_wall ? 0.0 : 1.0);
	}
	vec4 color = mix(ground * shadow_factor, ground, is_wall);
	vec3 mixed_fire_color = fire_color * (mix(0.5, (time_sine + 1.0) * 0.5 + 1.0, fire_time_offset));
	color.rgb = mix(color.rgb, mixed_fire_color, (1.0 - smoothstep(0.0, 1.25, fire_diff)) * 0.5 * is_ground);
	vec4 flow = texture(flow_tex, UV);
	if (is_wall < 0.5 && flow.z > 0.0) {
		float width = 0.1;
		vec2 diag_uv = fract(inner_real_uv * 2.0);
		float v = smoothstep(width, width * 1.5, min(abs(diag_uv.x - diag_uv.y), abs(diag_uv.x - (1.0 - diag_uv.y))));
		color.rgb = mix(color.rgb, vec3(1.0, 0.0, 0.0), (1.0 - v) * smoothstep(0.0, 1.0, flow.z));
	}
    COLOR = mix(color, vec4(inner_uv, 0.0, 1.0), 0.0);
}
