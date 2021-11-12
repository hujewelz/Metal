//
//  Renderer.swift
//  HelloTexture
//
//  Created by huluobo on 2021/11/12.
//

import Foundation
import MetalKit

class Renderer: NSObject {
    
    let commandQueue: MTLCommandQueue
    
    var pipepineState: MTLRenderPipelineState?
    
    let device: MTLDevice
    
    var vertexBuffer: MTLBuffer?
    var indexBuffer: MTLBuffer?
    var textureBuffer: MTLBuffer?
    
    var texture: MTLTexture?
    
    init(device: MTLDevice, imageName: String? = nil) {
        self.device = device
        commandQueue = device.makeCommandQueue()!
        super.init()
        if let imageName = imageName, let texture = makeTexture(device: device, imageName: imageName) {
            self.texture = texture
            fragmentShaderName = "textureShader"
        }
        buildModel()
        buildSamplerState()
        buildPipelineState()
    }
    
    private var vertices: [Vertex] = [
        .init(position: vector_float3(-1, 1, 0),
              color: vector_float4(1, 0, 0, 1),
              texture: vector_float2(0, 1)), // v0
        .init(position: vector_float3(-1, -1, 0),
              color: vector_float4(0, 1, 0, 1),
              texture: vector_float2(0, 0)), // v1
        .init(position: vector_float3(1, -1, 0),
              color: vector_float4(0, 0, 1, 1),
              texture: vector_float2(1, 0)), // v2
        .init(position: vector_float3(1, 1, 0),
              color: vector_float4(1, 0, 1, 1),
              texture: vector_float2(1, 1)), // v3
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
   
    private var fragmentShaderName = "fragmentShader"
    private func buildPipelineState() {
        let defaultLibrary = device.makeDefaultLibrary()
        let vertexFunction = defaultLibrary?.makeFunction(name: "vertexShader")
        let fragmentFunction = defaultLibrary?.makeFunction(name: fragmentShaderName)
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        let vertexDescriptor = MTLVertexDescriptor()
        // Position
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.attributes[0].offset = 0
        // Color
        vertexDescriptor.attributes[1].format = .float4
        vertexDescriptor.attributes[1].offset = MemoryLayout<vector_float3>.stride
        vertexDescriptor.attributes[1].bufferIndex = 0
        // Texture coordinate
        vertexDescriptor.attributes[2].format = .float2
        vertexDescriptor.attributes[2].offset = MemoryLayout<vector_float3>.stride + MemoryLayout<vector_float4>.stride
        vertexDescriptor.attributes[2].bufferIndex = 0
        
        vertexDescriptor.layouts[0].stride = MemoryLayout<Vertex>.stride
        
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        
        do {
            pipepineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch let error {
            print(error)
        }
    }
    
    private var samplerState: MTLSamplerState?
    private func buildSamplerState() {
        let descriptor = MTLSamplerDescriptor()
        descriptor.minFilter = .linear
        descriptor.magFilter = .linear
        samplerState = device.makeSamplerState(descriptor: descriptor)
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
        renderEncoder?.setFragmentSamplerState(samplerState, index: 0)
        
        renderEncoder?.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder?.setFragmentTexture(texture, index: 0)
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

extension Renderer: Texturable {}
