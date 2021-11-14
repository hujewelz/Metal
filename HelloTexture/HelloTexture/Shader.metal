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

struct Constants {
    float4x4 modelViewMatrix;
};

vertex VertexOut vertexShader(const VertexIn vertexIn [[ stage_in ]],
                              constant Constants &modelConstants [[ buffer(1) ]] )
{
    VertexOut out;
    out.positon = modelConstants.modelViewMatrix * float4(vertexIn.position, 1.0);
    out.color = vertexIn.color;
    out.texuteCoordinate = vertexIn.textureCoordinate;
    return out;
}

fragment half4 fragmentShader(VertexOut in [[ stage_in ]])
{
    return half4(in.color);
}

fragment half4 textureShader(VertexOut in [[ stage_in ]],
                              sampler sampler2d [[ sampler(0) ]],
                              texture2d<float> texture [[ texture(0) ]])
{
    float4 color = texture.sample(sampler2d, in.texuteCoordinate);
    return half4(color);
}


constant half3 rec709Luma = half3(0.2126, 0.7152, 0.0722);

kernel void grayscaleTexture(texture2d<half, access::read> inTexture [[ texture(0) ]],
                           texture2d<half, access::write> outTexture [[ texture(1) ]],
                           uint2 gid [[ thread_position_in_grid ]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
        // Return early if the pixel is out of bounds
        return;
    }
    half4 inColor = inTexture.read(gid);
    half gray = dot(inColor.rgb, rec709Luma);
    outTexture.write(half4(gray, gray, gray, 1.0), gid);
}
