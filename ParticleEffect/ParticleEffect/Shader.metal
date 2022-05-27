//
//  Shader.metal
//  ParticleEffect
//
//  Created by huluobo on 2021/11/22.
//

#include <metal_stdlib>
using namespace metal;

struct Particle {
    float2 position;
    float2 velocity;
    float4 color;
};

kernel void clear(texture2d<half, access::write> tex [[ texture(0) ]],
                  uint2 id [[ thread_position_in_grid ]]) {
    tex.write(half4(0, 0, 0, 1), id);
}

kernel void draw_dots(device Particle *particles [[ buffer(0) ]],
                            texture2d<half, access::write> tex [[ texture(0)]],
                            uint id [[ thread_position_in_grid ]]) {
    float width = tex.get_width();
    float height =tex.get_height();
    
    Particle particle;
    particle = particles[id];
   
    float2 position = particle.position;
    float2 velocity = particle.velocity;
    half4 color = half4(particle.color);
    
    position += particle.velocity;
    if (position.x < 0 || position.x > width) velocity.x *= -1;
    if (position.y < 0 || position.y > height) velocity.y *= -1;
    
    particle.position = position;
    particle.velocity = velocity;
    particles[id] = particle;
    
    uint2 texposition = uint2(position);
    tex.write(color, texposition);
    tex.write(color, texposition + uint2(1, 0));
    tex.write(color, texposition + uint2(0, 1));
    tex.write(color, texposition + uint2(-1, 0));
    tex.write(color, texposition + uint2(0, -1));
}


