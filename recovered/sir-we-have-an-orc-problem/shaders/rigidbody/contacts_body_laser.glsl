#[compute]
#version 450


layout(local_size_x = 64, local_size_y = 1, local_size_z = 1) in;

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

struct Contact
{
    vec2 world_pos;
    int self_id;
    int other_id;
};

layout(set = 0, binding = 2, std430) buffer RB_SimBuffer
{
    RB_Sim rb_sims[];
} _64;

layout(set = 1, binding = 5, std430) buffer WorldGridLaserCounts
{
    uint grid_laser_counts[];
} _153;

layout(set = 1, binding = 3, std430) buffer WorldGridCellCounts
{
    uint grid_cell_counts[];
} _166;

layout(set = 1, binding = 4, std430) buffer WorldGridBodyData
{
    WorldGridBody grid_bodies[];
} _190;

layout(set = 1, binding = 6, std430) buffer WorldGridLaserSegments
{
    vec4 grid_laser_segments[];
} _239;

layout(set = 2, binding = 4, std430) buffer ContactHandlerDamageReadback
{
    uint write_index;
    uint _padding1;
    uint _padding2;
    uint _padding3;
    int data[];
} contact_handler_damage_readback;

layout(set = 0, binding = 0, std430) buffer RB_Counts
{
    uint rb_count;
    uint rb_addition_count;
    uint rb_removal_count;
    uint rb_laser_segment_count;
} _333;

layout(set = 0, binding = 1, std430) buffer RB_PhysicsBuffer
{
    RB_Physics rb_physics[];
} _338;

layout(set = 0, binding = 3, std430) buffer RB_TmpBuffer
{
    RB_Tmp rb_tmps[];
} _343;

layout(set = 0, binding = 4, std430) buffer RB_ContactHandlers
{
    RB_ContactHandler rb_contact_handlers[];
} _357;

layout(set = 0, binding = 5, std430) buffer RB_Additions
{
    RB_Init rb_additions[];
} _363;

layout(set = 0, binding = 6, std430) buffer RB_Removals
{
    uint rb_removals[];
} _368;

layout(set = 0, binding = 7, std430) buffer RigidbodyEnemiesKilledReadback
{
    uint body_enemies_killed_readback[];
} _373;

layout(set = 0, binding = 8, std430) buffer RigidbodyEnemiesAliveReadback
{
    uint body_enemies_alive_readback[];
} _377;

layout(set = 0, binding = 9, std430) buffer RB_TypeCounts
{
    uint rb_type_counts[];
} _381;

layout(set = 0, binding = 10, std430) buffer RB_TypeIDs
{
    uint rb_type_ids[];
} _385;

layout(set = 0, binding = 11, std430) buffer RB_LaserSegments
{
    vec4 rb_laser_segments[];
} _389;

layout(set = 1, binding = 2, std430) buffer WorldBaseDamageReadback
{
    int world_base_damage_readback[];
} _398;

layout(set = 1, binding = 7, std430) buffer WorldReadbackGrid
{
    uint world_readback_grid_write_index;
    uint _padding1;
    uint _padding2;
    uint _padding3;
    uint world_readback_grid_enemies_alive[];
} _402;

layout(set = 2, binding = 0, std430) buffer ContactCount
{
    uint contact_count;
    uint _contact_count_pad0;
    uint _contact_count_pad1;
    uint _contact_count_pad2;
} _406;

layout(set = 2, binding = 1, std430) buffer Contacts
{
    Contact contacts[];
} _411;

layout(set = 2, binding = 2, std430) buffer ContactsPreFiltered
{
    int contact_bucket_meta[];
} _415;

layout(set = 2, binding = 3, std430) buffer ContactsPreFilteredData
{
    uvec2 contact_bucket_data[];
} _419;

layout(push_constant, std430) uniform PushConstants
{
    uvec2 grid_cell_count;
    vec2 grid_cell_size;
    uint time_ms;
    uint max_lasers_per_cell;
    float laser_damage;
    int laser_damage_report_id;
} pc;

layout(set = 1, binding = 0) uniform sampler2D world_sdf_tex;
layout(set = 1, binding = 1) uniform sampler2D world_flow_tex;

bool rb_is_in_layer(uint meta, uint layer_mask)
{
    return (((meta >> uint(0)) & 255u) & layer_mask) != 0u;
}

bool line_intersects_circle(vec2 start, vec2 end, vec2 center, float radius)
{
    vec2 segment = end - start;
    float t = clamp(dot(center - start, segment) / dot(segment, segment), 0.0, 1.0);
    vec2 closest_point = start + (segment * t);
    vec2 d = center - closest_point;
    return dot(d, d) <= (radius * radius);
}

void rb_deal_damage(float damage, uint id, uint time_ms, out int dealt_damage_i, out bool is_dead)
{
    if (damage <= 0.0)
    {
        dealt_damage_i = 0;
        is_dead = false;
        return;
    }
    int damage_i = int(damage * 100.0);
    int _72 = atomicAdd(_64.rb_sims[id].health, -damage_i);
    int health_before = _72;
    if (health_before <= 0)
    {
        dealt_damage_i = 0;
        is_dead = true;
        return;
    }
    int health_after = health_before - damage_i;
    if (time_ms > 0u)
    {
        uint timer = 268435456u | (time_ms & 268435455u);
        _64.rb_sims[id].timer = timer;
    }
    dealt_damage_i = min(health_before, damage_i);
    is_dead = health_after <= 0;
}

void main()
{
    uint local = gl_LocalInvocationID.x;
    uint cell_index = gl_WorkGroupID.x;
    uint cell_laser_count = _153.grid_laser_counts[cell_index];
    if (cell_laser_count == 0u)
    {
        return;
    }
    uint cell_body_count = _166.grid_cell_counts[cell_index * 2u];
    if (local >= cell_body_count)
    {
        return;
    }
    uint cell_offset = (cell_index * 64u) * 2u;
    uint _193 = cell_offset + local;
    WorldGridBody gb;
    gb.pred_pos = _190.grid_bodies[_193].pred_pos;
    gb.physics_meta = _190.grid_bodies[_193].physics_meta;
    gb.sim_meta = _190.grid_bodies[_193].sim_meta;
    gb.inv_mass = _190.grid_bodies[_193].inv_mass;
    gb.radius = _190.grid_bodies[_193].radius;
    gb.body_id = _190.grid_bodies[_193].body_id;
    gb._gb_padding_0 = _190.grid_bodies[_193]._gb_padding_0;
    uint param = gb.physics_meta;
    uint param_1 = 1u;
    if (!rb_is_in_layer(param, param_1))
    {
        return;
    }
    int param_9;
    bool param_10;
    for (uint i = 0u; i < cell_laser_count; i++)
    {
        vec4 segment = _239.grid_laser_segments[(cell_index * pc.max_lasers_per_cell) + i];
        vec2 param_2 = segment.xy;
        vec2 param_3 = segment.zw;
        vec2 param_4 = gb.pred_pos;
        float param_5 = gb.radius * 1.5;
        if (line_intersects_circle(param_2, param_3, param_4, param_5))
        {
            int dealt_damage_i = 0;
            bool is_dead = false;
            float param_6 = pc.laser_damage;
            uint param_7 = gb.body_id;
            uint param_8 = pc.time_ms;
            rb_deal_damage(param_6, param_7, param_8, param_9, param_10);
            dealt_damage_i = param_9;
            is_dead = param_10;
            bool _289 = dealt_damage_i > 0;
            bool _296;
            if (_289)
            {
                _296 = pc.laser_damage_report_id >= 0;
            }
            else
            {
                _296 = _289;
            }
            bool _304;
            if (_296)
            {
                _304 = uint(pc.laser_damage_report_id) < 32u;
            }
            else
            {
                _304 = _296;
            }
            if (_304)
            {
                uint buffer_index = contact_handler_damage_readback.write_index;
                uint write_index = (buffer_index * 32u) + uint(pc.laser_damage_report_id);
                int _324 = atomicAdd(contact_handler_damage_readback.data[write_index], dealt_damage_i);
            }
        }
    }
}


