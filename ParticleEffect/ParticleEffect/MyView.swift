//
//  MyView.swift
//  ParticleEffect
//
//  Created by huluobo on 2021/11/22.
//

import MetalKit

class MyView: MTKView {
    var commandQueue: MTLCommandQueue?
    var clearState: MTLComputePipelineState!
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    override func draw(_ dirtyRect: NSRect) {
        guard let clearState = clearState,
              let drawable = currentDrawable else { return }
        let commandBuffer = commandQueue?.makeCommandBuffer()
        let computeEncoder = commandBuffer?.makeComputeCommandEncoder()
        computeEncoder?.setComputePipelineState(clearState)
        computeEncoder?.setTexture(drawable.texture, index: 0)
        
        let w = clearState.threadExecutionWidth
        let h = clearState.maxTotalThreadsPerThreadgroup / w
        let threadgroupSize = MTLSize(width: w, height: h, depth: 1)
        
        let width = (drawable.texture.width + w - 1) / w
        let height = (drawable.texture.height + h - 1) / h
        let threadgroupCount = MTLSize(width: width, height: height, depth: 1)
        computeEncoder?.dispatchThreadgroups(threadgroupCount, threadsPerThreadgroup: threadgroupSize)
        
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
        do {
            clearState = try device!.makeComputePipelineState(function: clearFunc!)
         
        } catch let error {
            print(error)
        }
    }
    
}

