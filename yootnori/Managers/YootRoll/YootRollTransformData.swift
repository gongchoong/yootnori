//
//  YootRollTransformData.swift
//  yootnori
//
//  Created by David Lee on 11/1/25.
//

import Foundation
import RealityKit
import RealityKitContent

struct YootRollTransformData: Codable {
    var translation: Vector3Data
    var rotation:   QuaternionData
    var scale:      Vector3Data

    init(_ t: Transform) {
        translation = Vector3Data(t.translation)
        rotation = QuaternionData(t.rotation)
        scale = Vector3Data(t.scale)
    }

    func asTransform() -> Transform {
        Transform(
            scale: scale.simd,
            rotation: rotation.simd,
            translation: translation.simd
        )
    }
}

struct Vector3Data: Codable {
    var x: Float
    var y: Float
    var z: Float

    init(_ v: SIMD3<Float>) {
        x = v.x
        y = v.y
        z = v.z
    }

    var simd: SIMD3<Float> {
        SIMD3<Float>(x, y, z)
    }
}

struct QuaternionData: Codable {
    var x: Float
    var y: Float
    var z: Float
    var w: Float

    init(_ q: simd_quatf) {
        x = q.vector.x
        y = q.vector.y
        z = q.vector.z
        w = q.vector.w
    }

    var simd: simd_quatf {
        simd_quatf(ix: x, iy: y, iz: z, r: w)
    }
}

// Snapshot of ALL yoots at a single time point
struct ThrowFrame: Codable {
    let timestamp: TimeInterval
    let yootTransforms: [YootRollTransformData]
}

// Final package sent to other players after host finishes
struct ThrowReplayPackage: Codable {
    let throwID: UUID
    let frames: [ThrowFrame]
    let result: [Yoot]
}
