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
} _47;

layout(set = 3, binding = 1, std430) buffer ExplosionBuffer
{
    Explosion explosions[];
} _52;

layout(set = 3, binding = 2, std430) buffer LightningCounts
{
    int lightning_active_count;
    int lightning_inactive_count;
    uint _lightning_padding0;
    uint _lightning_padding1;
    uint lightning_ids[];
} _56;

layout(set = 3, binding = 3, std430) buffer LightningBuffer
{
    Lightning lightnings[];
} _61;

layout(push_constant, std430) uniform PushConstants
{
    mat4 camera_matrix;
    vec2 world_size;
    uint time_ms;
    uint time_render_ms;
} pc;

layout(location = 0) in vec2 uv;
layout(location = 0) out vec4 out_color;

void main()
{
    vec2 delta = uv - vec2(0.5);
    float dist = length(delta);
    float alpha = 1.0 - smoothstep(0.4799999892711639404296875, 0.5, dist);
    out_color = vec4(8.0, 4.0, 0.0, 1.0 * alpha);
}


