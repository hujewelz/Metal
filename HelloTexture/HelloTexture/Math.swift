//
//  Math.swift
//  HelloTexture
//
//  Created by luobobo on 2021/11/13.
//

import simd


func radians(from degrees: Float) -> Float {
    return (degrees / 180) * Float.pi
}

func degrees(from radians: Float) -> Float {
    return (radians / Float.pi) * 180
}

extension Float {
    var radiansToDegrees: Float {
        degrees(from: self)
    }
    
    var degreesToRadians: Float {
        radians(from: self)
    }
}

extension matrix_float4x4 {
    init(translationX x: Float, y: Float, z: Float) {
        self.init(columns:(
            simd_float4(1, 0, 0, 0),
            simd_float4(0, 1, 0, 0),
            simd_float4(0, 0, 1, 0),
            simd_float4(x, y, z, 1)
        ))
    }
    
    init(scaleX x: Float, y: Float, z: Float) {
        self.init(columns:(
            simd_float4(x, 0, 0, 0),
            simd_float4(0, y, 0, 0),
            simd_float4(0, 0, z, 0),
            simd_float4(0, 0, 0, 1)
        ))
    }
    
    
    func translate(byX x: Float, y: Float, z: Float) -> matrix_float4x4 {
        let translateMatrix = matrix_float4x4(translationX: x, y: y, z: z)
        return matrix_multiply(self, translateMatrix)
    }
    
    func scale(byX x: Float, y: Float, z: Float) -> matrix_float4x4 {
        let scaleMatrix = matrix_float4x4(scaleX: x, y: y, z: z)
        return matrix_multiply(self, scaleMatrix)
    }
    
}
