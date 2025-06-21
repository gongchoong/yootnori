//
//  ThrowViewModel.swift
//  yootnori
//
//  Created by David Lee on 6/17/25.
//

import Foundation
import RealityKit

class ThrowViewModel: ObservableObject {
    enum Constants {
        static var xOffset: Float = 0.00005
        static var yOffset: Float = 0.0004
        static var zOffset: Float = 0.00005
    }

    @Published var entities: [Entity] = []
    @Published var wasMoving = false
    @Published var started = false
    @Published var landed = false

    var allEntitiesMoving: Bool {
        entities.allSatisfy({ $0.isMoving() })
    }

    var shouldStartCheckingForLanding: Bool {
        guard started, !landed, wasMoving || allEntitiesMoving else { return false }
        return true
    }

    func roll() {
        for entity in entities {
            if let physicsEntity = entity as? (Entity & HasPhysicsBody) {
                // Generate a small random X offset
                let randomX = Float.random(in: -Constants.xOffset...Constants.xOffset)

                // Apply impulse with random lateral component
                let impulse = SIMD3<Float>(randomX, Constants.yOffset, 0)
                physicsEntity.applyImpulse(impulse, at: .zero, relativeTo: nil)
            }
        }
        landed = false
        started = true
    }

    func checkForLanding(completion: @escaping() -> ()) {
        var currentlyMoving = false

        for entity in entities {
            if entity.isMoving() {
                currentlyMoving = true
                break
            }
        }

        // Detect landing (transition from moving to stopped)
        if wasMoving && !currentlyMoving && !landed {
            landed = true
            print("🎯 Yoots have just landed!")

            for entity in entities {
                if isEntityUpsideDown(entity) {
                    print("🚫 \(entity.name) is upside down!")
                } else {
                    print("✅ \(entity.name) landed upright.")
                }
            }
            completion()
        }

        wasMoving = currentlyMoving
    }

    private func isEntityUpsideDown(_ entity: Entity) -> Bool {
        // Get the world transform of the entity
        let worldTransform = entity.transformMatrix(relativeTo: nil)

        // Based on your model import, column 2 seems to be your local "up" axis
        let localUpVector = SIMD3<Float>(
            worldTransform.columns.2.x,
            worldTransform.columns.2.y,
            worldTransform.columns.2.z
        )

        // Normalize to avoid floating-point issues
        let normalizedUp = simd_normalize(localUpVector)

        // World up vector in RealityKit coordinate system
        let worldUp = SIMD3<Float>(0, 1, 0)

        // Compute dot product to get angle alignment
        let dotProduct = simd_dot(normalizedUp, worldUp)

        print("\(entity.name) dot product: \(dotProduct)")

        // Tolerance threshold — adjust if needed
        if dotProduct < -0.7 {
            return true // upside down
        } else {
            return false // upright or sideways
        }
    }
}
