struct VS_INPUT {
    float2 world_pos: POSITION;
};

struct VS_OUTPUT {
    float4 clip_pos: SV_POSITION;
    float2 camera_relative_world_pos: TEXCOORD0; // feeds frac() in PS
};

cbuffer CameraBuffer : register(b0) {
    matrix view_projection;
};
cbuffer TileParams: register(b1) {
    float4 atlas_rect;
    float2 tile_size_world;
    float2 parallax_factor;
    float2 camera_pos;
};



VS_OUTPUT VSMain(VS_INPUT input) {
    VS_OUTPUT output;
    output.clip_pos = mul(view_projection, float4(input.world_pos, 0.0, 1.0));
    output.camera_relative_world_pos = input.world_pos - camera_pos; // parallax-scaled camera pos from cbuffer
    return output;
}

Texture2D tex : register(t0);
SamplerState samp : register(s0);

float4 PSMain(VS_OUTPUT input) : SV_TARGET
{
    float2 tile_space = input.camera_relative_world_pos.xy / tile_size_world;
    float2 local_uv = frac(tile_space);
    float2 atlas_uv = lerp(atlas_rect.xy, atlas_rect.zw, local_uv);
    float4 color = tex.Sample(samp, atlas_uv);

    return color;
}

