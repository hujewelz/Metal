//
//  MyView.swift
//  ParticleEffect
//
//  Created by huluobo on 2021/11/22.
//

import MetalKit

struct Particle {
    let position: vector_float2
    let velocity: vector_float2
    let color: vector_float4
}

class MyView: MTKView {
    
    @IBOutlet weak var hslider: NSSlider!
    @IBOutlet weak var texField: NSTextField!
    
    
    var commandQueue: MTLCommandQueue?
    var clearState: MTLComputePipelineState!
    var drawState: MTLComputePipelineState!
    
    var particleBuffer: MTLBuffer?
    
    var particleCount = 10
    
    var screenWidth: Float { Float(drawableSize.width) }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        setup()
        buildParticles()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        hslider.floatValue = Float(particleCount)
        texField.stringValue = "\(particleCount)"
    }
    
    @IBAction func update(_ sender: Any) {
        guard let value = Int(texField.stringValue) else { return }
        hslider.floatValue = Float(value)
        particleCount = value
        
        let queue = DispatchQueue.global(qos: .default)
        queue.async {
            self.buildParticles()
        }
    }
    
    @IBAction func sliderValueChanged(_ sender: NSSlider) {
        let value = Int(sender.floatValue)
        texField.stringValue = "\(value)"
    }
    
    
    override func draw(_ dirtyRect: NSRect) {
        guard let clearState = clearState,
              let drawState = drawState,
              let drawable = currentDrawable else { return }
        let commandBuffer = commandQueue?.makeCommandBuffer()
        let computeEncoder = commandBuffer?.makeComputeCommandEncoder()
        computeEncoder?.setComputePipelineState(clearState)
        computeEncoder?.setTexture(drawable.texture, index: 0)
        
        let w = clearState.threadExecutionWidth
        let h = clearState.maxTotalThreadsPerThreadgroup / w
        var threadgroupSize = MTLSize(width: w, height: h, depth: 1)
        
        /* 1.
         let width = (drawable.texture.width + w - 1) / w
         let height = (drawable.texture.height + h - 1) / h
         let threadgroupCount = MTLSize(width: width, height: height, depth: 1)
         computeEncoder?.dispatchThreadgroups(threadgroupCount, threadsPerThreadgroup: threadgroupSize)
         */
        // or 2.
        var threadsPerGrid = MTLSize(width: drawable.texture.width, height: drawable.texture.height, depth: 1)
        computeEncoder?.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadgroupSize)
        
        computeEncoder?.setComputePipelineState(drawState)
        computeEncoder?.setBuffer(particleBuffer, offset: 0, index: 0)
        threadgroupSize = MTLSize(width: drawState.threadExecutionWidth, height: 1, depth: 1)
        threadsPerGrid = MTLSize(width: particleCount, height: 1, depth: 1)
        computeEncoder?.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadgroupSize)
        
        computeEncoder?.endEncoding()
        commandBuffer?.present(drawable)
        commandBuffer?.commit()
    }
}

extension MyView {
    
    private func setup() {
        
        device = MTLCreateSystemDefaultDevice()
        commandQueue = device!.makeCommandQueue()
        framebufferOnly = false
        
        let library = device!.makeDefaultLibrary()
        let clearFunc = library?.makeFunction(name: "clear")
        let drawdotFunc = library?.makeFunction(name: "draw_dots")
        do {
            clearState = try device!.makeComputePipelineState(function: clearFunc!)
            drawState = try device!.makeComputePipelineState(function: drawdotFunc!)
        } catch let error {
            print(error)
        }
    }
    
    
    private func buildParticles() {
        let particles = (0...particleCount).map { _ -> Particle in
            let r = Float(arc4random_uniform(100)) / 100
            let g = Float(arc4random_uniform(100)) / 100
            let b = Float(arc4random_uniform(100)) / 100
            let particle = Particle(position: vector_float2(Float(arc4random_uniform(UInt32(screenWidth))),
                                                            Float(arc4random_uniform(UInt32(screenWidth)))),
                                    velocity: vector_float2((Float(arc4random() % 10) - 5) / 10,
                                                            (Float(arc4random() % 10) - 5) / 10),
                                    color: vector_float4(r, g, b, 1))
            return particle
        }
        
        let length = MemoryLayout<Particle>.stride * particles.count
        particleBuffer = device?.makeBuffer(bytes: particles, length: length, options: [])
    }
    
}

