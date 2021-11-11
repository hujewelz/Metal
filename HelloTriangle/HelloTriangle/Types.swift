//
//  shaderType.swift
//  UsingRenderPipeline
//
//  Created by huluobo on 2021/11/11.
//

import Foundation
import simd

struct Vertex {
    let position: vector_float3
    let color: vector_float4
}

enum VertexInputIndex {
    static let vertices = 0
}
