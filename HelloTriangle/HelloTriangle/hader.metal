//
//  vertexShader.metal
//  UsingRenderPipeline
//
//  Created by huluobo on 2021/11/11.
//

#include <metal_stdlib>

using namespace metal;

struct VertexIn
{
    float3 position;
    float3 color;
};

struct VertexOut {
    float4 position [[position]];
    float4 color;
};

vertex VertexOut
vertexShader(uint vertexID [[vertex_id]],
             constant VertexIn *vertices [[buffer(0)]])
{
    VertexOut out;
    out.position =  float4(vertices[vertexID].position, 1);
    out.color = float4(vertices[vertexID].color, 1);
    return out;
}

fragment float4 fragmentShader(VertexOut in [[stage_in]])
{
    return in.color;
}
