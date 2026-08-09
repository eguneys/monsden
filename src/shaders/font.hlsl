// Compiled offline by fxc.exe (see build.zig) into DXBC bytecode that gets
// @embedFile'd into the exe -- nothing in main.zig calls D3DCompile.

struct VSInput
{
    float3 pos   : POSITION;
    float2 uv : TEXCOORD0;
    float4 color: COLOR0;
};

struct PSInput
{
    float4 pos   : SV_POSITION;
    float2 uv : TEXCOORD0;
    float4 color: COLOR0;
};

cbuffer CameraBuffer : register(b0) {
    matrix view_projection;
};

PSInput VSMain(VSInput input)
{
    PSInput output;
    output.pos = mul(view_projection, float4(input.pos, 1.0));
    output.uv = input.uv;
    output.color = input.color;
    return output;
}

Texture2D atlas_tex : register(t0);
SamplerState samp : register(s0);

float4 PSMain(PSInput input) : SV_TARGET
{
    //return float4(0.0, 1.0, 0.0, 1.0);
    //return atlas_tex.Sample(samp, input.uv);
    float coverage = atlas_tex.Sample(samp, input.uv).r;
    return float4(input.color.rgb, input.color.a * coverage);
}

