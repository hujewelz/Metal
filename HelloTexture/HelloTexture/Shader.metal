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
    float3 position;
};

struct VertexOut
{
    float4 positon [[position]];
    float4 color;
};

vertex VertexOut vertexShader(constant VertexIn *vertices [[buffer(0)]], uint vertexId [[vertex_id]])
{
    VertexOut out;
    out.positon = float4(vertices[vertexId].position, 1.0);
    out.color = float4(1.0, 0.0, 0.0, 1.0);
    return out;
}

fragment float4 fragmentShader(VertexOut in [[stage_in]])
{
    return in.color;
}
