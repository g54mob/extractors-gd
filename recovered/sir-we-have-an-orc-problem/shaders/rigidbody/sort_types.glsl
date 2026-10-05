#[compute]
#version 450


layout(local_size_x = 256, local_size_y = 1, local_size_z = 1) in;

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

struct RB_Physics
{
    vec2 position;
    vec2 velocity;
    float radius;
    float inv_mass;
    uint meta;
    uint freeze_end_time_ms;
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
} _34;

layout(set = 0, binding = 2, std430) buffer RB_SimBuffer
{
    RB_Sim rb_sims[];
} _76;

layout(set = 0, binding = 9, std430) buffer RB_TypeCounts
{
    uint rb_type_counts[];
} _116;

layout(set = 0, binding = 10, std430) buffer RB_TypeIDs
{
    uint rb_type_ids[];
} _135;

layout(set = 0, binding = 1, std430) buffer RB_PhysicsBuffer
{
    RB_Physics rb_physics[];
} _154;

layout(set = 0, binding = 3, std430) buffer RB_TmpBuffer
{
    RB_Tmp rb_tmps[];
} _159;

layout(set = 0, binding = 4, std430) buffer RB_ContactHandlers
{
    RB_ContactHandler rb_contact_handlers[];
} _176;

layout(set = 0, binding = 5, std430) buffer RB_Additions
{
    RB_Init rb_additions[];
} _182;

layout(set = 0, binding = 6, std430) buffer RB_Removals
{
    uint rb_removals[];
} _187;

layout(set = 0, binding = 7, std430) buffer RigidbodyEnemiesKilledReadback
{
    uint body_enemies_killed_readback[];
} _192;

layout(set = 0, binding = 8, std430) buffer RigidbodyEnemiesAliveReadback
{
    uint body_enemies_alive_readback[];
} _196;

layout(set = 0, binding = 11, std430) buffer RB_LaserSegments
{
    vec4 rb_laser_segments[];
} _201;

shared uint counts[5];
shared uint global_offsets[5];

uint rb_get_layer_mask(uint meta)
{
    return (meta >> uint(0)) & 255u;
}

void main()
{
    uint id = gl_GlobalInvocationID.x;
    bool is_valid = id < _34.rb_count;
    if (gl_LocalInvocationID.x == 0u)
    {
        for (uint i = 0u; i < 5u; i++)
        {
            counts[i] = 0u;
        }
    }
    barrier();
    uint layer_id = 0u;
    uint local_offset = 0u;
    if (is_valid)
    {
        uint param = _76.rb_sims[id].meta;
        uint layer = rb_get_layer_mask(param);
        layer_id = uint(findLSB(layer));
        uint _89 = atomicAdd(counts[layer_id], 1u);
        local_offset = _89;
    }
    barrier();
    if ((gl_LocalInvocationID.x == 0u) && is_valid)
    {
        for (uint i_1 = 0u; i_1 < 5u; i_1++)
        {
            if (counts[i_1] > 0u)
            {
                uint _122 = atomicAdd(_116.rb_type_counts[i_1], counts[i_1]);
                global_offsets[i_1] = _122;
            }
            else
            {
                global_offsets[i_1] = 0u;
            }
        }
    }
    barrier();
    if (is_valid)
    {
        _135.rb_type_ids[((layer_id * 262144u) + global_offsets[layer_id]) + local_offset] = id;
    }
}


