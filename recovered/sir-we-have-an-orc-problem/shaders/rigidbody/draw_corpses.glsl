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
} _38;

layout(set = 0, binding = 1, std430) buffer RB_PhysicsBuffer
{
    RB_Physics rb_physics[];
} _43;

layout(set = 0, binding = 2, std430) buffer RB_SimBuffer
{
    RB_Sim rb_sims[];
} _49;

layout(set = 0, binding = 3, std430) buffer RB_TmpBuffer
{
    RB_Tmp rb_tmps[];
} _54;

layout(set = 0, binding = 4, std430) buffer RB_ContactHandlers
{
    RB_ContactHandler rb_contact_handlers[];
} _75;

layout(set = 0, binding = 5, std430) buffer RB_Additions
{
    RB_Init rb_additions[];
} _81;

layout(set = 0, binding = 6, std430) buffer RB_Removals
{
    uint rb_removals[];
} _86;

layout(set = 0, binding = 7, std430) buffer RigidbodyEnemiesKilledReadback
{
    uint body_enemies_killed_readback[];
} _91;

layout(set = 0, binding = 8, std430) buffer RigidbodyEnemiesAliveReadback
{
    uint body_enemies_alive_readback[];
} _95;

layout(set = 0, binding = 9, std430) buffer RB_TypeCounts
{
    uint rb_type_counts[];
} _99;

layout(set = 0, binding = 10, std430) buffer RB_TypeIDs
{
    uint rb_type_ids[];
} _103;

layout(set = 0, binding = 11, std430) buffer RB_LaserSegments
{
    vec4 rb_laser_segments[];
} _107;

layout(push_constant, std430) uniform PushConstants
{
    mat4 camera_matrix;
    vec2 world_size;
} pc;

layout(set = 3, binding = 0) uniform sampler2D color_tex;

layout(location = 0) in vec2 uv;
layout(location = 0) out vec4 out_color;
layout(location = 1) flat in float random;

void main()
{
    vec4 color = texture(color_tex, uv);
    color.w *= 0.60000002384185791015625;
    out_color = color;
}


