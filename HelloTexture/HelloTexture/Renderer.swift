//
//  Renderer.swift
//  HelloTexture
//
//  Created by huluobo on 2021/11/12.
//

import Foundation
import MetalKit

class Renderer: NSObject {
    let view: MTKView
    
    let commandQueue: MTLCommandQueue
    
    var pipepineState: MTLRenderPipelineState?
    
    var device: MTLDevice { view.device! }
    
    var vertexBuffer: MTLBuffer?
    var indexBuffer: MTLBuffer?
    var textureBuffer: MTLBuffer?
    
    init(view: MTKView) {
        self.view = view
        commandQueue = view.device!.makeCommandQueue()!
        super.init()
        buildModel()
        buildPipelineState()
    }
    
    private var vertices: [Vertex] = [
        .init(position: vector_float3(-1, 1, 0)), // v0
        .init(position: vector_float3(-1, -1, 0)), // v1
        .init(position: vector_float3(1, -1, 0)), // v2
        .init(position: vector_float3(1, 1, 0)), // v3
    ]
    
    private var indices: [UInt16] = [
        0, 1, 2,
        2, 3, 0,
    ]
    
    private func buildModel() {
        vertexBuffer = device.makeBuffer(bytes: vertices,
                                           length: MemoryLayout<Vertex>.stride * vertices.count,
                                           options: [])
        indexBuffer = device.makeBuffer(bytes: indices,
                                          length: MemoryLayout.size(ofValue: indices[0]) * indices.count,
                                          options: [])
    }
    
    private func buildPipelineState() {
        let defaultLibrary = device.makeDefaultLibrary()
        let vertexFunction = defaultLibrary?.makeFunction(name: "vertexShader")
        let fragmentFunction = defaultLibrary?.makeFunction(name: "fragmentShader")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
        
        do {
            pipepineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch let error {
            print(error)
        }
    }
}

extension Renderer: MTKViewDelegate {
    func draw(in view: MTKView) {
        
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        guard let indexBuffer = indexBuffer,
              let pipelineState = pipepineState,
              let renderPassDescriptor = view.currentRenderPassDescriptor,
              let drawable = view.currentDrawable else { return }
        let commondBuffer = commandQueue.makeCommandBuffer()
        let renderEncoder = commondBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        
        renderEncoder?.setRenderPipelineState(pipelineState)
        
        renderEncoder?.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        renderEncoder?.drawIndexedPrimitives(type: .triangle,
                                             indexCount: indices.count,
                                             indexType: .uint16,
                                             indexBuffer: indexBuffer,
                                             indexBufferOffset: 0,
                                             instanceCount: 1)
        
        renderEncoder?.endEncoding()
        commondBuffer?.present(drawable)
        commondBuffer?.commit()
    }
}
