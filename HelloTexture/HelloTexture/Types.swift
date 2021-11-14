//
//  Types.swift
//  HelloTexture
//
//  Created by huluobo on 2021/11/12.
//

import Foundation
import simd

struct Vertex {
    let position: vector_float3
    let color: vector_float4
    let texture: vector_float2
}

struct ModelConstants {
    var modelViewMatrix = matrix_identity_float4x4
}
