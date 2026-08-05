// Compiled offline by fxc.exe (see build.zig) into DXBC bytecode that gets
// @embedFile'd into the exe -- nothing in main.zig calls D3DCompile.

struct VSInput
{
    float3 pos   : POSITION;
    float2 uv : TEXCOORD0;
};

struct PSInput
{
    float4 pos   : SV_POSITION;
    float2 uv : TEXCOORD0;
};

PSInput VSMain(VSInput input)
{
    PSInput output;
    output.pos = float4(input.pos, 1.0);
    output.uv = input.uv;
    return output;
}

Texture2D tex0 : register(t0);
SamplerState samp0 : register(s0);

float4 PSMain(PSInput input) : SV_TARGET
{
    //return float4(1.0, 0.0, 0.0, 1.0);
    return tex0.Sample(samp0, input.uv);
}
