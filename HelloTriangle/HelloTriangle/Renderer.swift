//
//  Renderer.swift
//  UsingRenderPipeline
//
//  Created by huluobo on 2021/11/11.
//

import Cocoa
import MetalKit
import simd

class Renderer: NSObject {
    let view: MTKView
    
    var device: MTLDevice { view.device! }
    
    var commandQueue: MTLCommandQueue?
    
    var pipelineState: MTLRenderPipelineState!

    var vertexBuffer: MTLBuffer?
    
    init(view: MTKView) {
        self.view = view
        commandQueue = view.device!.makeCommandQueue()
        super.init()
        
        buildModel()
        buildPipelineState()
        
    }
    
    let vertices: [Vertex] = [
        .init(position: vector_float3(0, 1, 0), color: vector_float4(1, 0, 0, 1)),
        .init(position: vector_float3(-1, -1, 0), color: vector_float4(0, 1, 0, 1)),
        .init(position: vector_float3(1, -1, 0), color: vector_float4(0, 0, 1, 1)),
    ]
    
    func buildModel() {
        let length = MemoryLayout<Vertex>.stride * vertices.count
        vertexBuffer = device.makeBuffer(bytes: vertices, length: length, options: [])
    }

    func buildPipelineState() {
        let defaultLibrary = device.makeDefaultLibrary()
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.label = "My Shader pipeline"
        pipelineDescriptor.vertexFunction = defaultLibrary?.makeFunction(name: "vertexShader")
        pipelineDescriptor.fragmentFunction = defaultLibrary?.makeFunction(name: "fragmentShader")
        pipelineDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
        
        do {
            pipelineState = try view.device?.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch let error {
            print(error)
        }
    }
}

extension Renderer: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func draw(in view: MTKView) {
        guard let renderPassDescriptor = view.currentRenderPassDescriptor,
              let pipelineState = pipelineState else {
            return
        }
        
        let commandBuffer = commandQueue?.makeCommandBuffer()
        let commandEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)

        commandEncoder?.setRenderPipelineState(pipelineState)
        commandEncoder?.setVertexBuffer(vertexBuffer, offset: 0, index: VertexInputIndex.vertices)
        commandEncoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
    
        commandEncoder?.endEncoding()
        commandBuffer?.present(view.currentDrawable!)
        commandBuffer?.commit()
    }
}
