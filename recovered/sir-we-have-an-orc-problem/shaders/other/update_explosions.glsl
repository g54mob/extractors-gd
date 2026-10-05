#[compute]
#version 450


layout(local_size_x = 256, local_size_y = 1, local_size_z = 1) in;

struct Explosion
{
    vec2 position;
    float radius;
    float lifetime;
};

struct Lightning
{
    vec2 start;
    vec2 end;
    float lifetime;
    float _padding_0;
    float _padding_1;
    float _padding_2;
};

layout(set = 3, binding = 1, std430) buffer ExplosionBuffer
{
    Explosion explosions[];
} _47;

layout(set = 3, binding = 0, std430) buffer ExplosionCounts
{
    int explosion_active_count;
    int explosion_inactive_count;
    uint _explosion_padding0;
    uint _explosion_padding1;
    uint explosion_ids[];
} _94;

layout(set = 3, binding = 2, std430) buffer LightningCounts
{
    int lightning_active_count;
    int lightning_inactive_count;
    uint _lightning_padding0;
    uint _lightning_padding1;
    uint lightning_ids[];
} _142;

layout(set = 3, binding = 3, std430) buffer LightningBuffer
{
    Lightning lightnings[];
} _147;

layout(push_constant, std430) uniform PushConstants
{
    float dt;
} pc;

shared uint active_count;
shared uint inactive_count;
shared uint global_active_offset;
shared uint global_inactive_offset;

void main()
{
    uint id = gl_GlobalInvocationID.x;
    bool is_valid = id < 4096u;
    if (gl_LocalInvocationID.x == 0u)
    {
        active_count = 0u;
        inactive_count = 0u;
    }
    barrier();
    bool is_active = false;
    uint local_offset = 0u;
    if (is_valid)
    {
        float lifetime = _47.explosions[id].lifetime;
        is_active = lifetime > pc.dt;
        _47.explosions[id].lifetime = lifetime - pc.dt;
        uint _70;
        if (is_active)
        {
            uint _74 = atomicAdd(active_count, 1u);
            _70 = _74;
        }
        else
        {
            uint _76 = atomicAdd(inactive_count, 1u);
            _70 = _76;
        }
        local_offset = _70;
    }
    barrier();
    if ((gl_LocalInvocationID.x == 0u) && is_valid)
    {
        uint _88;
        if (active_count > 0u)
        {
            int _99 = atomicAdd(_94.explosion_active_count, int(active_count));
            _88 = uint(_99);
        }
        else
        {
            _88 = 0u;
        }
        global_active_offset = _88;
        uint _106;
        if (inactive_count > 0u)
        {
            int _113 = atomicAdd(_94.explosion_inactive_count, int(inactive_count));
            _106 = uint(_113);
        }
        else
        {
            _106 = 0u;
        }
        global_inactive_offset = _106;
    }
    barrier();
    if (is_valid)
    {
        if (is_active)
        {
            _94.explosion_ids[global_active_offset + local_offset] = id;
        }
        else
        {
            _94.explosion_ids[(4096u + global_inactive_offset) + local_offset] = id;
        }
    }
}


