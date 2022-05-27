//
//  Renderer.swift
//  Video
//
//  Created by huluobo on 2021/11/23.
//

import MetalKit
import AVFoundation

struct Vertex {
    let position: vector_float3
    let texture: vector_float2
}

struct YUVToRGBMatrix {
    let matrix: matrix_float3x3;
    let offset: vector_float3;
}

enum FillMode {
    case strtch
    case aspectRatio
    case aspectRationToFill
}

final class Renderer: NSObject {
    
    private var commandQueue: MTLCommandQueue?
    private var renderPass: MTLRenderPipelineState!
    
    private var textureCache: CVMetalTextureCache?
    private var yTexture: MTLTexture?
    private var uvTexture: MTLTexture?
    
    private var vertexBuffer: MTLBuffer?
    private var matrixBuffer: MTLBuffer?
    
    var fillMode = FillMode.strtch {
        didSet {
            fillModeChanged = true
        }
    }
    
    let device: MTLDevice
    
    init(device: MTLDevice) {
        self.device = device
        super.init()
        
        CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil, &textureCache)
        commandQueue = device.makeCommandQueue()
        buildModel()
        setupMatrix()
        buildRenderPipelineState()
    }
   
    deinit {
        if let textureCache = textureCache {
            CVMetalTextureCacheFlush(textureCache, 0)
        }
    }

    private var widthScale: Float = 1
    private var heightScale: Float = 1
    private var vertices: [Vertex] = [
        .init(position: vector_float3(-1, -1, 0),
              texture: vector_float2(0, 1)),
        .init(position: vector_float3(-1, 1, 0),
              texture: vector_float2(0, 0)),
        .init(position: vector_float3(1, -1, 0),
              texture: vector_float2(1, 1)),
        .init(position: vector_float3(1, 1, 0),
              texture: vector_float2(1, 0)),
    ]
    
    private func buildModel() {
        
        vertexBuffer = device.makeBuffer(bytes: vertices,
                                           length: MemoryLayout<Vertex>.stride * vertices.count,
                                           options: [])
    }
    
    private func setupMatrix() {
        var matrix = YUVToRGBMatrix(matrix: YUVToRGBMatrix._601_FullRangeMatrix,
                                    offset: YUVToRGBMatrix._601_FullRangeOffset)
        matrixBuffer = device.makeBuffer(bytes: &matrix, length: MemoryLayout<YUVToRGBMatrix>.stride, options: [])
    }
    
    private var drawableSize = CGSize.zero
    private var fillModeChanged = true
    private func resetVertex(width: CGFloat, height: CGFloat) {
        let inputImageSize = CGSize(width: width, height: height)
        let bounds = UIScreen.main.bounds //CGRect(origin: .zero, size: drawableSize)
    
        let insetRect = AVMakeRect(aspectRatio: inputImageSize, insideRect: bounds)
        switch fillMode {
        case .strtch:
            widthScale = 1
            heightScale = 1
        case .aspectRatio:
            widthScale = Float(insetRect.size.width / bounds.width)
            heightScale = Float(insetRect.size.height / bounds.height)
        case .aspectRationToFill:
            widthScale = Float(bounds.width / insetRect.size.width )
            heightScale = Float(bounds.height / insetRect.size.height)
        }
        
        vertices = [
            .init(position: vector_float3(-1 * widthScale, -1 * heightScale, 0),
                  texture: vector_float2(1, 1)),
            .init(position: vector_float3(-1 * widthScale, 1 * heightScale, 0),
                  texture: vector_float2(0, 1)),
            .init(position: vector_float3(1 * widthScale, -1 * heightScale, 0),
                  texture: vector_float2(1, 0)),
            .init(position: vector_float3(1 * widthScale, 1 * heightScale, 0),
                  texture: vector_float2(0, 0)),
        ]
        buildModel()
    }
    
    private func buildRenderPipelineState() {
        let lib = device.makeDefaultLibrary()
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = lib?.makeFunction(name: "vertex_func")
        descriptor.fragmentFunction = lib?.makeFunction(name: "fragment_func")
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        do {
            renderPass = try device.makeRenderPipelineState(descriptor: descriptor)
        } catch let error {
            print(error)
        }
    }
    
    
    func didReceive(_ pixelBuffer: CVPixelBuffer) {
        setupTexture(pixelBuffer)
    }
    
    private func makeTexture(from pixelBuffer: CVPixelBuffer, pixelFormat: MTLPixelFormat, plane: Int) -> MTLTexture? {
        var texture: MTLTexture?
        
        let width = CVPixelBufferGetWidthOfPlane(pixelBuffer, plane)
        let height = CVPixelBufferGetHeightOfPlane(pixelBuffer, plane)
        var metalTexture: CVMetalTexture?
        guard let textureCache = textureCache else { return nil }
        let status = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                               textureCache,
                                                               pixelBuffer,
                                                               nil,
                                                               pixelFormat,
                                                               width,
                                                               height,
                                                               plane,
                                                               &metalTexture)
        
        if status == kCVReturnSuccess {
            texture = CVMetalTextureGetTexture(metalTexture!)
        } else {
            CVMetalTextureCacheFlush(textureCache, 0)
        }
        return texture
    }
    
    private func setupTexture(_ pixelBuffer: CVPixelBuffer) {
        // Y 纹理
        let yWidth = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0)
        let yHeight = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0)
        
        if fillModeChanged {
            resetVertex(width: CGFloat(yWidth), height: CGFloat(yHeight))
            fillModeChanged = false
        }
        
        yTexture = makeTexture(from: pixelBuffer, pixelFormat: .r8Unorm, plane: 0)
        uvTexture = makeTexture(from: pixelBuffer, pixelFormat: .rg8Unorm, plane: 1)
    }
    
    
}

extension Renderer: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        drawableSize = size
    }
    
    func draw(in view: MTKView) {
        guard let renderPassDesc = view.currentRenderPassDescriptor,
              let drawable = view.currentDrawable else { return }
        let commandBuffer = commandQueue?.makeCommandBuffer()
        let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDesc)
        renderEncoder?.setRenderPipelineState(renderPass)
        renderEncoder?.setViewport(MTLViewport(originX: 0, originY: 0, width: drawableSize.width, height: drawableSize.height, znear: 0, zfar: 1))
        renderEncoder?.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder?.setFragmentBuffer(matrixBuffer, offset: 0, index: 0)
        renderEncoder?.setFragmentTexture(yTexture, index: 0)
        renderEncoder?.setFragmentTexture(uvTexture, index: 1)
        renderEncoder?.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: vertices.count)
        
        renderEncoder?.endEncoding()
        commandBuffer?.present(drawable)
        commandBuffer?.commit()
    }
}

extension YUVToRGBMatrix {
    static var _601_DefaultMatrix: matrix_float3x3 {
        matrix_float3x3(vector_float3(1.164, 1.164, 1.164),
                        vector_float3(0.0, -0.392, 2.017),
                        vector_float3(1.596, -0.813, 0.0))
    }
    
    static var _601_FullRangeMatrix: matrix_float3x3 {
        matrix_float3x3(vector_float3(1.0, 1.0, 1.0),
                        vector_float3(0.0, -0.343, 1.765),
                        vector_float3(1.4, -0.711, 0.0))
    }
    
    static var _709_DefaultMatrix: matrix_float3x3 {
        matrix_float3x3(vector_float3(1.164, 1.164, 1.164),
                        vector_float3(0.0, -0.213, 2.112),
                        vector_float3(1.793, -0.533, 0.0))
    }
    
    static var _601_FullRangeOffset: vector_float3 {
        vector_float3(-(16.0/255.0), -0.5, -0.5)
    }
}
