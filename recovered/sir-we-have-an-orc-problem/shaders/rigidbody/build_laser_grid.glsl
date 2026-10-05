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

layout(set = 1, binding = 5, std430) buffer WorldGridLaserCounts
{
    uint grid_laser_counts[];
} _78;

layout(set = 1, binding = 6, std430) buffer WorldGridLaserSegments
{
    vec4 grid_laser_segments[];
} _93;

layout(set = 0, binding = 0, std430) buffer RB_Counts
{
    uint rb_count;
    uint rb_addition_count;
    uint rb_removal_count;
    uint rb_laser_segment_count;
} _113;

layout(set = 0, binding = 11, std430) buffer RB_LaserSegments
{
    vec4 rb_laser_segments[];
} _125;

layout(set = 0, binding = 1, std430) buffer RB_PhysicsBuffer
{
    RB_Physics rb_physics[];
} _316;

layout(set = 0, binding = 2, std430) buffer RB_SimBuffer
{
    RB_Sim rb_sims[];
} _321;

layout(set = 0, binding = 3, std430) buffer RB_TmpBuffer
{
    RB_Tmp rb_tmps[];
} _326;

layout(set = 0, binding = 4, std430) buffer RB_ContactHandlers
{
    RB_ContactHandler rb_contact_handlers[];
} _346;

layout(set = 0, binding = 5, std430) buffer RB_Additions
{
    RB_Init rb_additions[];
} _352;

layout(set = 0, binding = 6, std430) buffer RB_Removals
{
    uint rb_removals[];
} _357;

layout(set = 0, binding = 7, std430) buffer RigidbodyEnemiesKilledReadback
{
    uint body_enemies_killed_readback[];
} _362;

layout(set = 0, binding = 8, std430) buffer RigidbodyEnemiesAliveReadback
{
    uint body_enemies_alive_readback[];
} _366;

layout(set = 0, binding = 9, std430) buffer RB_TypeCounts
{
    uint rb_type_counts[];
} _370;

layout(set = 0, binding = 10, std430) buffer RB_TypeIDs
{
    uint rb_type_ids[];
} _374;

layout(set = 1, binding = 2, std430) buffer WorldBaseDamageReadback
{
    int world_base_damage_readback[];
} _383;

layout(set = 1, binding = 3, std430) buffer WorldGridCellCounts
{
    uint grid_cell_counts[];
} _387;

layout(set = 1, binding = 4, std430) buffer WorldGridBodyData
{
    WorldGridBody grid_bodies[];
} _392;

layout(set = 1, binding = 7, std430) buffer WorldReadbackGrid
{
    uint world_readback_grid_write_index;
    uint _padding1;
    uint _padding2;
    uint _padding3;
    uint world_readback_grid_enemies_alive[];
} _396;

layout(push_constant, std430) uniform PushConstants
{
    uvec2 grid_cell_count;
    vec2 grid_cell_size;
    uint max_lasers_per_cell;
} pc;

layout(set = 1, binding = 0) uniform sampler2D world_sdf_tex;
layout(set = 1, binding = 1) uniform sampler2D world_flow_tex;

void emit_cell(ivec2 cell, vec4 segment)
{
    bool _24 = cell.x < 0;
    bool _40;
    if (!_24)
    {
        _40 = cell.x >= int(pc.grid_cell_count.x);
    }
    else
    {
        _40 = _24;
    }
    bool _48;
    if (!_40)
    {
        _48 = cell.y < 0;
    }
    else
    {
        _48 = _40;
    }
    bool _58;
    if (!_48)
    {
        _58 = cell.y >= int(pc.grid_cell_count.y);
    }
    else
    {
        _58 = _48;
    }
    if (_58)
    {
        return;
    }
    uint cell_index = (uint(cell.y) * pc.grid_cell_count.x) + uint(cell.x);
    uint _82 = atomicAdd(_78.grid_laser_counts[cell_index], 1u);
    uint index_in_cell = _82;
    if (index_in_cell < pc.max_lasers_per_cell)
    {
        _93.grid_laser_segments[(cell_index * pc.max_lasers_per_cell) + index_in_cell] = segment;
    }
}

void main()
{
    uint id = gl_GlobalInvocationID.x;
    if (id >= _113.rb_laser_segment_count)
    {
        return;
    }
    vec4 segment = _125.rb_laser_segments[id];
    vec2 start = segment.xy;
    vec2 end = segment.zw;
    vec2 dir = end - start;
    ivec2 cell = ivec2(floor(start / pc.grid_cell_size));
    if (all(equal(start, end)))
    {
        ivec2 param = cell;
        vec4 param_1 = segment;
        emit_cell(param, param_1);
        return;
    }
    ivec2 end_cell = ivec2(floor(end / pc.grid_cell_size));
    ivec2 _step = ivec2(sign(dir));
    vec2 inv_dir = vec2(1.0) / dir;
    vec2 t_delta = abs(pc.grid_cell_size * inv_dir);
    float _189;
    if (_step.x > 0)
    {
        _189 = float(cell.x + 1) * pc.grid_cell_size.x;
    }
    else
    {
        _189 = float(cell.x) * pc.grid_cell_size.x;
    }
    float _211;
    if (_step.y > 0)
    {
        _211 = float(cell.y + 1) * pc.grid_cell_size.y;
    }
    else
    {
        _211 = float(cell.y) * pc.grid_cell_size.y;
    }
    vec2 next_boundary = vec2(_189, _211);
    vec2 t_max = (next_boundary - start) * inv_dir;
    while (true)
    {
        ivec2 param_2 = cell;
        vec4 param_3 = segment;
        emit_cell(param_2, param_3);
        bool _251 = cell.x == end_cell.x;
        bool _259;
        if (_251)
        {
            _259 = cell.y == end_cell.y;
        }
        else
        {
            _259 = _251;
        }
        if (_259)
        {
            break;
        }
        if (t_max.x < t_max.y)
        {
            cell.x += _step.x;
            t_max.x += t_delta.x;
        }
        else
        {
            if (t_max.y < t_max.x)
            {
                cell.y += _step.y;
                t_max.y += t_delta.y;
            }
            else
            {
                cell += _step;
                t_max += t_delta;
            }
        }
    }
}


