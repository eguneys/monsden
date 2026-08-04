// Draws a single fullscreen triangle from SV_VertexID (no vertex/index
// buffer needed) and samples the offscreen game render target onto it.
// The letterbox/pillarbox centering and integer scaling are done by how
// main.zig sets the viewport before this draw, not by anything in here.

Texture2D game_tex : register(t0);
SamplerState game_sampler : register(s0);

struct VSOutput
{
    float4 pos : SV_POSITION;
    float2 uv  : TEXCOORD0;
};

VSOutput VSMain(uint vertex_id : SV_VertexID)
{
    VSOutput output;
    output.uv = float2((vertex_id << 1) & 2, vertex_id & 2);
    output.pos = float4(output.uv * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
    return output;
}

float4 PSMain(VSOutput input) : SV_TARGET
{
    return game_tex.Sample(game_sampler, input.uv);
}
