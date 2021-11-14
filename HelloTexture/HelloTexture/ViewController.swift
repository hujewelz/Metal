//
//  ViewController.swift
//  HelloTexture
//
//  Created by huluobo on 2021/11/12.
//

import Cocoa
import MetalKit

class ViewController: NSViewController {
    
    var mtkView: MTKView { view as! MTKView }
    
    var renderer: Renderer!

    override func viewDidLoad() {
        super.viewDidLoad()

        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.clearColor = MTLClearColor(red: 0.1, green: 0.2, blue: 0.3, alpha: 1.0)
        mtkView.colorPixelFormat = .bgra8Unorm
        
        renderer = Renderer(device: mtkView.device!, imageName: "hero.jpg")
        mtkView.delegate = renderer
        
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

