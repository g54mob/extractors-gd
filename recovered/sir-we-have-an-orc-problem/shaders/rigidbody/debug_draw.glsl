#[fragment]
#version 450



struct RB_Physics
{
    vec2 position;
    vec2 velocity;
    float radius;
    float inv_mass;
    uint meta;
    uint freeze_end_time_ms;
};

struct RB_Sim
{
    float lifetime;
    int health;
    uint timer;
    uint meta;
    uint fire_end_time_ms;
    uint shock_end_time_ms;
    uint slow_end_time_ms;
    uint speed_factor_i;
};

struct RB_Tmp
{
    vec2 previous_position;
    vec2 predicted_position;
    vec2 position_delta;
    int grid_index;
    int _padding_0;
};

struct RB_ContactHandler
{
    float damage_self;
    float damage_other;
    float damage_falloff;
    float fire_timer;
    uint flags;
    int chaining;
    int damage_report_id;
    float slow_timer;
};

struct RB_Init
{
    vec2 position;
    vec2 velocity;
    float radius;
    float inv_mass;
    float health;
    float lifetime;
    uint physics_meta;
    uint sim_meta;
    uint _padding_0;
    uint _padding_1;
    float ch_damage_self;
    float ch_damage_other;
    float ch_damage_falloff;
    float ch_fire_timer;
    uint ch_flags;
    int ch_chaining;
    int ch_damage_report_id;
    float ch_slow_timer;
};

layout(set = 0, binding = 0, std430) buffer RB_Counts
{
    uint rb_count;
    uint rb_addition_count;
    uint rb_removal_count;
    uint rb_laser_segment_count;
} _544;

layout(set = 0, binding = 1, std430) buffer RB_PhysicsBuffer
{
    RB_Physics rb_physics[];
} _549;

layout(set = 0, binding = 2, std430) buffer RB_SimBuffer
{
    RB_Sim rb_sims[];
} _554;

layout(set = 0, binding = 3, std430) buffer RB_TmpBuffer
{
    RB_Tmp rb_tmps[];
} _559;

layout(set = 0, binding = 4, std430) buffer RB_ContactHandlers
{
    RB_ContactHandler rb_contact_handlers[];
} _572;

layout(set = 0, binding = 5, std430) buffer RB_Additions
{
    RB_Init rb_additions[];
} _578;

layout(set = 0, binding = 6, std430) buffer RB_Removals
{
    uint rb_removals[];
} _583;

layout(set = 0, binding = 7, std430) buffer RigidbodyEnemiesKilledReadback
{
    uint body_enemies_killed_readback[];
} _588;

layout(set = 0, binding = 8, std430) buffer RigidbodyEnemiesAliveReadback
{
    uint body_enemies_alive_readback[];
} _592;

layout(set = 0, binding = 9, std430) buffer RB_TypeCounts
{
    uint rb_type_counts[];
} _596;

layout(set = 0, binding = 10, std430) buffer RB_TypeIDs
{
    uint rb_type_ids[];
} _600;

layout(set = 0, binding = 11, std430) buffer RB_LaserSegments
{
    vec4 rb_laser_segments[];
} _604;

layout(push_constant, std430) uniform PushConstants
{
    mat4 camera_matrix;
    vec2 world_size;
    uint time_ms;
    uint time_render_ms;
} pc;

layout(set = 3, binding = 0) uniform sampler2D enemy_tex;
layout(set = 3, binding = 1) uniform sampler2D grenade_tex;

layout(location = 2) flat in uint meta;
layout(location = 3) flat in uint timer;
layout(location = 8) flat in float frozen_factor;
layout(location = 1) flat in float random;
layout(location = 0) in vec2 uv;
layout(location = 11) flat in uint was_burned;
layout(location = 10) flat in float factor_sum;
layout(location = 9) flat in float golden_factor;
layout(location = 5) flat in float fire_factor;
layout(location = 7) flat in float shock_factor;
layout(location = 6) flat in float slow_factor;
layout(location = 0) out vec4 out_color;
layout(location = 4) flat in float ch_slowing;

uint rb_get_layer_mask(uint meta_1)
{
    return (meta_1 >> uint(0)) & 255u;
}

vec3 rgb2hsv(vec3 c)
{
    vec4 K = vec4(0.0, -0.3333333432674407958984375, 0.666666686534881591796875, -1.0);
    vec4 p = mix(vec4(c.zy, K.wz), vec4(c.yz, K.xy), vec4(step(c.z, c.y)));
    vec4 q = mix(vec4(p.xyw, c.x), vec4(c.x, p.yzx), vec4(step(p.x, c.x)));
    float d = q.x - min(q.w, q.y);
    float e = 1.0000000133514319600180897396058e-10;
    return vec3(abs(q.z + ((q.w - q.y) / ((6.0 * d) + e))), d / (q.x + e), q.x);
}

bool rb_has_flags(uint sim_meta, uint flags)
{
    return (((sim_meta >> uint(8)) & 255u) & (flags & 255u)) == (flags & 255u);
}

vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 0.666666686534881591796875, 0.3333333432674407958984375, 3.0);
    vec3 p = abs((fract(c.xxx + K.xyz) * 6.0) - K.www);
    return mix(K.xxx, clamp(p - K.xxx, vec3(0.0), vec3(1.0)), vec3(c.y)) * c.z;
}

void main()
{
    uint param = meta;
    uint layer = rb_get_layer_mask(param);
    uint timer_time = timer & 268435455u;
    uint timer_type = timer >> 28u;
    uint time_diff = pc.time_render_ms - timer_time;
    if ((layer & 1u) != 0u)
    {
        float time_render_s = float(pc.time_render_ms) * 0.001000000047497451305389404296875;
        float _226;
        if (frozen_factor > 0.0)
        {
            _226 = random;
        }
        else
        {
            _226 = fract((time_render_s + random) * 1.33333337306976318359375);
        }
        float anim_time = _226;
        uint sprite_index = uint(floor(anim_time * 6.0));
        float variations = ceil(float(textureSize(enemy_tex, 0).y) / 32.0);
        float variation_index = floor((random * 0.999000012874603271484375) * variations);
        float uv_offset_y = variation_index / variations;
        float uv_step_y = 1.0 / variations;
        vec2 uv_offset = vec2(0.16666667163372039794921875 * float(sprite_index), uv_offset_y);
        vec4 color = texture(enemy_tex, uv_offset + (uv * vec2(0.16666667163372039794921875, uv_step_y)));
        vec3 param_1 = color.xyz;
        vec3 hsv = rgb2hsv(param_1);
        hsv.x = clamp(hsv.x + ((-0.100000001490116119384765625) + (random * 0.20000000298023223876953125)), 0.0, 1.0);
        hsv = mix(hsv, vec3(hsv.x, hsv.y * 0.89999997615814208984375, hsv.z * 0.4000000059604644775390625), vec3(float(was_burned > 0u)));
        uint param_2 = meta;
        uint param_3 = 8u;
        if (rb_has_flags(param_2, param_3))
        {
            hsv.x = 0.0;
            hsv.y = 2.0;
            hsv.z = mix(2.0, 5.0, fract(((float(pc.time_render_ms) * 0.001000000047497451305389404296875) + random) * 3.0));
        }
        float factor_multiplier = 1.0 / max(factor_sum, 1.0);
        hsv = mix(hsv, vec3(0.14499999582767486572265625, 0.100000001490116119384765625, hsv.z), vec3(golden_factor * factor_multiplier));
        hsv = mix(hsv, vec3(0.07999999821186065673828125, 1.0, hsv.z * 2.0), vec3(fire_factor * factor_multiplier));
        hsv = mix(hsv, vec3(0.550000011920928955078125, 2.0, hsv.z * 3.0), vec3(shock_factor * factor_multiplier));
        hsv = mix(hsv, vec3(0.87000000476837158203125, 1.0, hsv.z), vec3(slow_factor * factor_multiplier));
        hsv = mix(hsv, vec3(0.64999997615814208984375, 1.0, hsv.z), vec3(frozen_factor * factor_multiplier));
        vec3 param_4 = hsv;
        out_color = vec4(hsv2rgb(param_4) * mix(1.0, 10.0, factor_sum), color.w);
    }
    else
    {
        if ((layer & 2u) != 0u)
        {
            vec2 delta = uv - vec2(0.5);
            float dist = length(delta);
            float alpha = 1.0 - smoothstep(0.4799999892711639404296875, 0.5, dist);
            vec3 color_1 = mix(vec3(1.0, 0.550000011920928955078125, 0.0199999995529651641845703125), vec3(0.800000011920928955078125, 0.0199999995529651641845703125, 1.0), bvec3(ch_slowing > 0.0)) * 8.0;
            out_color = vec4(color_1, alpha);
        }
        else
        {
            if ((layer & 32u) != 0u)
            {
                out_color = texture(grenade_tex, uv);
            }
            else
            {
                if ((layer & 8u) != 0u)
                {
                    vec2 delta_1 = uv - vec2(0.5);
                    float dist_1 = length(delta_1);
                    float alpha_1 = 1.0 - smoothstep(0.4799999892711639404296875, 0.5, dist_1);
                    vec4 color_2 = mix(vec4(0.800000011920928955078125, 0.0199999995529651641845703125, 1.0, 0.20000000298023223876953125), vec4(0.0199999995529651641845703125, 0.800000011920928955078125, 1.0, 0.20000000298023223876953125), bvec4(frozen_factor > 0.0));
                    out_color = vec4(color_2.xyz, color_2.w * alpha_1);
                }
                else
                {
                    out_color = vec4(1.0, 0.0, 1.0, 1.0);
                }
            }
        }
    }
    if ((timer_type == 1u) && (time_diff < 400u))
    {
        float damaged_factor = float(time_diff) / 400.0;
        vec4 _527 = out_color;
        vec3 _531 = mix(mix(vec3(2.0), vec3(0.5, 0.0, 0.0), vec3(clamp(damaged_factor * 2.0, 0.0, 1.0))), _527.xyz, vec3(damaged_factor));
        out_color.x = _531.x;
        out_color.y = _531.y;
        out_color.z = _531.z;
    }
}


