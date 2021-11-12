//
//  Texturable.swift
//  HelloTexture
//
//  Created by huluobo on 2021/11/12.
//

import MetalKit

protocol Texturable {
    var texture: MTLTexture? { get set }
}

extension Texturable {
    func makeTexture(device: MTLDevice, imageName: String) -> MTLTexture? {
        let textureLoader = MTKTextureLoader(device: device)
        guard let url = Bundle.main.url(forResource: imageName, withExtension: nil) else { return nil }
        return try? textureLoader.newTexture(URL: url, options: [.origin: MTKTextureLoader.Origin.bottomLeft])
    }
}
