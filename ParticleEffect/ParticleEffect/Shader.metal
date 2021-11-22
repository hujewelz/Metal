//
//  Shader.metal
//  ParticleEffect
//
//  Created by huluobo on 2021/11/22.
//

#include <metal_stdlib>
using namespace metal;

kernel void clear(texture2d<half, access::write> tex [[ texture(0) ]],
                  uint2 id [[ thread_position_in_grid ]]) {
    tex.write(half4(1, 0, 0, 1), id);
}


