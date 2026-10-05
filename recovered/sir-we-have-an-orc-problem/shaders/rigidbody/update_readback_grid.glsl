#[compute]
#version 450


layout(local_size_x = 256, local_size_y = 1, local_size_z = 1) in;

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

struct WorldGridBody
{
    vec2 pred_pos;
    uint physics_meta;
    uint sim_meta;
    float inv_mass;
    float radius;
    uint body_id;
    uint _gb_padding_0;
};

layout(set = 0, binding = 0, std430) buffer RB_Counts
{
    uint rb_count;
    uint rb_addition_count;
    uint rb_removal_count;
    uint rb_laser_segment_count;
} _52;

layout(set = 0, binding = 1, std430) buffer RB_PhysicsBuffer
{
    RB_Physics rb_physics[];
} _69;

layout(set = 1, binding = 7, std430) buffer WorldReadbackGrid
{
    uint world_readback_grid_write_index;
    uint _padding1;
    uint _padding2;
    uint _padding3;
    uint world_readback_grid_enemies_alive[];
} _159;

layout(set = 0, binding = 2, std430) buffer RB_SimBuffer
{
    RB_Sim rb_sims[];
} _199;

layout(set = 0, binding = 3, std430) buffer RB_TmpBuffer
{
    RB_Tmp rb_tmps[];
} _204;

layout(set = 0, binding = 4, std430) buffer RB_ContactHandlers
{
    RB_ContactHandler rb_contact_handlers[];
} _223;

layout(set = 0, binding = 5, std430) buffer RB_Additions
{
    RB_Init rb_additions[];
} _229;

layout(set = 0, binding = 6, std430) buffer RB_Removals
{
    uint rb_removals[];
} _234;

layout(set = 0, binding = 7, std430) buffer RigidbodyEnemiesKilledReadback
{
    uint body_enemies_killed_readback[];
} _239;

layout(set = 0, binding = 8, std430) buffer RigidbodyEnemiesAliveReadback
{
    uint body_enemies_alive_readback[];
} _243;

layout(set = 0, binding = 9, std430) buffer RB_TypeCounts
{
    uint rb_type_counts[];
} _247;

layout(set = 0, binding = 10, std430) buffer RB_TypeIDs
{
    uint rb_type_ids[];
} _251;

layout(set = 0, binding = 11, std430) buffer RB_LaserSegments
{
    vec4 rb_laser_segments[];
} _256;

layout(set = 1, binding = 2, std430) buffer WorldBaseDamageReadback
{
    int world_base_damage_readback[];
} _265;

layout(set = 1, binding = 3, std430) buffer WorldGridCellCounts
{
    uint grid_cell_counts[];
} _269;

layout(set = 1, binding = 4, std430) buffer WorldGridBodyData
{
    WorldGridBody grid_bodies[];
} _274;

layout(set = 1, binding = 5, std430) buffer WorldGridLaserCounts
{
    uint grid_laser_counts[];
} _278;

layout(set = 1, binding = 6, std430) buffer WorldGridLaserSegments
{
    vec4 grid_laser_segments[];
} _282;

layout(push_constant, std430) uniform PushConstants
{
    uvec2 readback_grid_cell_count;
    vec2 readback_grid_cell_size;
    uint time_ms;
} pc;

layout(set = 1, binding = 0) uniform sampler2D world_sdf_tex;
layout(set = 1, binding = 1) uniform sampler2D world_flow_tex;

bool rb_is_in_layer(uint meta, uint layer_mask)
{
    return (((meta >> uint(0)) & 255u) & layer_mask) != 0u;
}

bool rb_has_flags(uint sim_meta, uint flags)
{
    return (((sim_meta >> uint(8)) & 255u) & (flags & 255u)) == (flags & 255u);
}

void main()
{
    uint id = gl_GlobalInvocationID.x;
    if (id >= _52.rb_count)
    {
        return;
    }
    RB_Physics physics;
    physics.position = _69.rb_physics[id].position;
    physics.velocity = _69.rb_physics[id].velocity;
    physics.radius = _69.rb_physics[id].radius;
    physics.inv_mass = _69.rb_physics[id].inv_mass;
    physics.meta = _69.rb_physics[id].meta;
    physics.freeze_end_time_ms = _69.rb_physics[id].freeze_end_time_ms;
    vec2 p = physics.position;
    ivec2 ip = ivec2(floor(p / pc.readback_grid_cell_size));
    bool _113 = ip.x < 0;
    bool _124;
    if (!_113)
    {
        _124 = uint(ip.x) >= pc.readback_grid_cell_count.x;
    }
    else
    {
        _124 = _113;
    }
    bool _132;
    if (!_124)
    {
        _132 = ip.y < 0;
    }
    else
    {
        _132 = _124;
    }
    bool _142;
    if (!_132)
    {
        _142 = uint(ip.y) >= pc.readback_grid_cell_count.y;
    }
    else
    {
        _142 = _132;
    }
    if (_142)
    {
        return;
    }
    uint meta = physics.meta;
    uint param = meta;
    uint param_1 = 1u;
    if (rb_is_in_layer(param, param_1))
    {
        uint write_index = _159.world_readback_grid_write_index;
        uint base_buffer_offset = (write_index * pc.readback_grid_cell_count.x) * pc.readback_grid_cell_count.y;
        uint cell_index = (base_buffer_offset + (uint(ip.y) * pc.readback_grid_cell_count.x)) + uint(ip.x);
        uint param_2 = meta;
        uint param_3 = 1u;
        if (rb_has_flags(param_2, param_3))
        {
            uint _191 = atomicAdd(_159.world_readback_grid_enemies_alive[cell_index], 1u);
        }
    }
}


