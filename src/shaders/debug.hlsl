struct VSInput
{
    float2 pos   : POSITION;
    float4 color : COLOR0;
};

struct PSInput
{
    float4 pos   : SV_POSITION;
    float4 color : COLOR0;
};

cbuffer CameraBuffer : register(b0) {
    matrix view_projection;
};

PSInput VSMain(VSInput input)
{
    PSInput output;
    output.pos = mul(view_projection, float4(input.pos, 0.0, 1.0));
    output.color = input.color;
    return output;
}

float4 PSMain(PSInput input) : SV_TARGET
{
    return input.color;
}
