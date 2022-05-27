//
//  PreviewerView.swift
//  Video
//
//  Created by huluobo on 2021/11/23.
//

import MetalKit
import CoreVideo

class PreviewerView: MTKView {

    var renderer: Renderer!
    
    override init(frame frameRect: CGRect, device: MTLDevice?) {
        super.init(frame: frameRect, device: device)
        setup()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    private func setup() {
        device = MTLCreateSystemDefaultDevice()
        colorPixelFormat = .bgra8Unorm
        clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        renderer = Renderer(device: device!)
        delegate = renderer
    }
    
    func didReceive(_ pixelBuffer: CVPixelBuffer) {
        renderer.didReceive(pixelBuffer)
    }
        
}
