#[fragment]
#version 450



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

layout(set = 3, binding = 0, std430) buffer ExplosionCounts
{
    int explosion_active_count;
    int explosion_inactive_count;
    uint _explosion_padding0;
    uint _explosion_padding1;
    uint explosion_ids[];
} _25;

layout(set = 3, binding = 1, std430) buffer ExplosionBuffer
{
    Explosion explosions[];
} _30;

layout(set = 3, binding = 2, std430) buffer LightningCounts
{
    int lightning_active_count;
    int lightning_inactive_count;
    uint _lightning_padding0;
    uint _lightning_padding1;
    uint lightning_ids[];
} _35;

layout(set = 3, binding = 3, std430) buffer LightningBuffer
{
    Lightning lightnings[];
} _40;

layout(push_constant, std430) uniform PushConstants
{
    mat4 camera_matrix;
    vec2 world_size;
    uint time_ms;
    uint time_render_ms;
} pc;

layout(location = 0) out vec4 out_color;
layout(location = 0) in vec2 uv;

void main()
{
    out_color = vec4(1.60000002384185791015625, 2.400000095367431640625, 8.0, 1.0);
}


