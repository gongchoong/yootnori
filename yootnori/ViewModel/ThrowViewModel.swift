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
        static var yoots: [String] = ["yoot_1", "yoot_2", "yoot_3", "yoot_4"]
        static var xOffset: Float = 0.00005
        static var yOffset: Float = 0.0004
        static var zOffset: Float = 0.00005
    }

    enum YootError: Error {
        case yootBoardNotFound
        case yootEntityNotFound
    }

    @Published var wasMoving = false
    @Published var started = false
    @Published var landed = false
    var yootThrowBoard: Entity?
    var yootEntities: [Entity] = []

    var allEntitiesMoving: Bool {
        yootEntities.allSatisfy({ $0.isMoving() })
    }

    var shouldStartCheckingForLanding: Bool {
        guard started, !landed, wasMoving || allEntitiesMoving else { return false }
        return true
    }

    func roll() {
        do {
            defer {
                landed = false
                started = true
            }
            // Find yoot entities from the YootThrowBoard entity
            if yootEntities.isEmpty {
                try loadYootEntities()
            }

            for entity in yootEntities {
                if let physicsEntity = entity as? (Entity & HasPhysicsBody) {
                    // Generate a small random X offset
                    let randomX = Float.random(in: -Constants.xOffset...Constants.xOffset)

                    // Apply impulse with random lateral component
                    let impulse = SIMD3<Float>(randomX, Constants.yOffset, 0)
                    physicsEntity.applyImpulse(impulse, at: .zero, relativeTo: nil)
                }
            }
        } catch let error {
            fatalError("\(error)")
        }
    }

    func checkForLanding(completion: @escaping() -> ()) {
        var currentlyMoving = false

        for yoot in yootEntities {
            if yoot.isMoving() {
                currentlyMoving = true
                break
            }
        }

        // Detect landing (transition from moving to stopped)
        if wasMoving && !currentlyMoving && !landed {
            landed = true
            print("🎯 Yoots have just landed!")

            for yoot in yootEntities {
                if isEntityUpsideDown(yoot) {
                    print("🚫 \(yoot.name) is upside down!")
                } else {
                    print("✅ \(yoot.name) landed upright.")
                }
            }
            completion()
        }

        wasMoving = currentlyMoving
    }

    private func loadYootEntities() throws {
        guard let yootThrowBoard else {
            throw YootError.yootBoardNotFound
        }
        for yoot in Constants.yoots {
            guard let yootEntity = yootThrowBoard.findEntity(named: yoot) else {
                throw YootError.yootEntityNotFound
            }
            yootEntities.append(yootEntity)
        }
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
