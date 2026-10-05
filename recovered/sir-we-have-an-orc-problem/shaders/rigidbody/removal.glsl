#[compute]
#version 450


layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

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

struct RB_Tmp
{
    vec2 previous_position;
    vec2 predicted_position;
    vec2 position_delta;
    int grid_index;
    int _padding_0;
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

layout(set = 0, binding = 1, std430) buffer RB_PhysicsBuffer
{
    RB_Physics rb_physics[];
} _39;

layout(set = 0, binding = 2, std430) buffer RB_SimBuffer
{
    RB_Sim rb_sims[];
} _51;

layout(set = 0, binding = 4, std430) buffer RB_ContactHandlers
{
    RB_ContactHandler rb_contact_handlers[];
} _62;

layout(set = 0, binding = 0, std430) buffer RB_Counts
{
    uint rb_count;
    uint rb_addition_count;
    uint rb_removal_count;
    uint rb_laser_segment_count;
} _72;

layout(set = 0, binding = 6, std430) buffer RB_Removals
{
    uint rb_removals[];
} _101;

layout(set = 0, binding = 3, std430) buffer RB_TmpBuffer
{
    RB_Tmp rb_tmps[];
} _159;

layout(set = 0, binding = 5, std430) buffer RB_Additions
{
    RB_Init rb_additions[];
} _179;

layout(set = 0, binding = 7, std430) buffer RigidbodyEnemiesKilledReadback
{
    uint body_enemies_killed_readback[];
} _184;

layout(set = 0, binding = 8, std430) buffer RigidbodyEnemiesAliveReadback
{
    uint body_enemies_alive_readback[];
} _188;

layout(set = 0, binding = 9, std430) buffer RB_TypeCounts
{
    uint rb_type_counts[];
} _192;

layout(set = 0, binding = 10, std430) buffer RB_TypeIDs
{
    uint rb_type_ids[];
} _196;

layout(set = 0, binding = 11, std430) buffer RB_LaserSegments
{
    vec4 rb_laser_segments[];
} _201;

bool rb_has_flags(uint sim_meta, uint flags)
{
    return (((sim_meta >> uint(8)) & 255u) & (flags & 255u)) == (flags & 255u);
}

void rb_copy(uint dst_id, uint src_id)
{
    _39.rb_physics[dst_id] = _39.rb_physics[src_id];
    _51.rb_sims[dst_id] = _51.rb_sims[src_id];
    _62.rb_contact_handlers[dst_id] = _62.rb_contact_handlers[src_id];
}

void main()
{
    uint removal_count = min(_72.rb_removal_count, 32768u);
    if (removal_count == 0u)
    {
        return;
    }
    uint src_id = _72.rb_count;
    for (uint i = 0u; i < removal_count; i++)
    {
        uint dst_id = _101.rb_removals[i];
        if (dst_id >= src_id)
        {
            continue;
        }
        bool _134;
        for (;;)
        {
            src_id--;
            uint src_meta = _51.rb_sims[src_id].meta;
            bool _125 = src_id > dst_id;
            if (_125)
            {
                uint param = src_meta;
                uint param_1 = 1u;
                _134 = !rb_has_flags(param, param_1);
            }
            else
            {
                _134 = _125;
            }
            if (_134)
            {
                continue;
            }
            else
            {
                break;
            }
        }
        if (src_id <= dst_id)
        {
            continue;
        }
        uint param_2 = dst_id;
        uint param_3 = src_id;
        rb_copy(param_2, param_3);
    }
    _72.rb_count = src_id;
}


