//
//  Shader.metal
//  HelloTexture
//
//  Created by huluobo on 2021/11/12.
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn
{
    float3 position [[attribute(0)]];
    float4 color [[attribute(1)]];
    float2 textureCoordinate [[attribute(2)]];
};

struct VertexOut
{
    float4 positon [[position]];
    float4 color;;
    float2 texuteCoordinate;
};

vertex VertexOut vertexShader(const VertexIn vertexIn [[stage_in]])
{
    VertexOut out;
    out.positon = float4(vertexIn.position, 1.0);
    out.color = vertexIn.color;
    out.texuteCoordinate = vertexIn.textureCoordinate;
    return out;
}

fragment float4 fragmentShader(VertexOut in [[stage_in]])
{
    return in.color;
}

fragment float4 textureShader(VertexOut in [[stage_in]],
                              sampler sampler2d [[sampler(0)]],
                              texture2d<float> texture [[texture(0)]])
{
    float4 color = texture.sample(sampler2d, in.texuteCoordinate);
    return color;
}
