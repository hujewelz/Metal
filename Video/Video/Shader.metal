//
//  Shader.metal
//  Video
//
//  Created by huluobo on 2021/11/23.
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float3 position;
    float2 textureCoordinate;
};

struct VertexOut {
    float4 position [[ position ]];
    float2 textureCoordinate;
};

struct YUVToRGB {
    float3x3 matrix;
    float3 offset;
};

vertex VertexOut vertex_func(constant VertexIn *in [[ buffer(0) ]],
                             uint id [[ vertex_id ]]) {
    VertexOut out;
    out.position = float4(in[id].position, 1);
    out.textureCoordinate = in[id].textureCoordinate;
    return out;
}

fragment half4 fragment_func(VertexOut in [[ stage_in ]],
                             texture2d<float> texY [[ texture(0) ]],
                             texture2d<float> texUV [[ texture(1) ]],
                             constant YUVToRGB &convertMatrix [[buffer(0)]]) {
    constexpr sampler textureSampler (mag_filter::linear, min_filter::linear);
    
    const float4x4 ycbcrToRGBTransform = float4x4(
            float4(+1.0000f, +1.0000f, +1.0000f, +0.0000f),
            float4(+0.0000f, -0.3441f, +1.7720f, +0.0000f),
            float4(+1.4020f, -0.7141f, +0.0000f, +0.0000f),
            float4(-0.7010f, +0.5291f, -0.8860f, +1.0000f)
        );

    float4 ycbcr = float4(texY.sample(textureSampler, in.textureCoordinate).r,
                          texUV.sample(textureSampler, in.textureCoordinate).rg, 1);
//    float4 rgba = convertMatrix.matrix * (yuv + convertMatrix.offset);
    float4 rgba = ycbcrToRGBTransform * ycbcr;
    return half4(rgba);
//    return  half4(1, 0, 0, 1);
}


