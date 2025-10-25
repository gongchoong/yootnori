//
//  ThrowViewModel.swift
//  yootnori
//
//  Created by David Lee on 6/17/25.
//

import Foundation
import RealityKit
import RealityKitContent
import SwiftUI
import Combine

protocol YootRollDelegate: AnyObject {
    func yootRollDidStartRoll()
    func yootRollDidFinishRoll()
    func yootRollDidRollDouble()
}

class YootRollManager: ObservableObject {
    enum Constants {
        static var yootEntityNames: [String] = ["yoot_1", "yoot_2", "yoot_3", "yoot_4"]
        static var xOffset: Float = 0.00009
        static var yOffset: Float = 0.00045
        static var zOffset: Float = 0.00009
    }

    enum YootRollError: Error {
        case yootBoardNotFound
        case yootEntityNotFound
    }

    weak var yootThrowBoard: Entity?
    weak var delegate: YootRollDelegate?
    var yootEntities: [Entity] = []

    @Published var result: [Yoot] = []
    var resultPublisher: Published<[Yoot]>.Publisher {
        $result
    }

    private var originalTransforms: [String: Transform] = [:]
    private var wasMoving = false
    private var landed = false
    private var isAnimating = false

    private var allEntitiesMoving: Bool {
        yootEntities.allSatisfy({ $0.isMoving() })
    }

    private var shouldStartCheckingForLanding: Bool {
        guard isAnimating, !landed, wasMoving || allEntitiesMoving else { return false }
        return true
    }

    func roll() async {
        delegate?.yootRollDidStartRoll()
        do {
            landed = false
            isAnimating = true
            // Find yoot entities from the YootThrowBoard entity
            if yootEntities.isEmpty {
                try loadYootEntities()
            }
            // Center all the yoots before starting the throw animation
            resetToOriginalPosition()

            for entity in yootEntities {
                if let physicsEntity = entity as? (Entity & HasPhysicsBody) {
                    // Generate a small random X offset
                    let randomX = Float.random(in: -Constants.xOffset...Constants.xOffset)
                    let randomZ = Float.random(in: -Constants.zOffset...Constants.zOffset)

                    // Apply impulse with random lateral component
                    var impulse = SIMD3<Float>(randomX, Constants.yOffset, randomZ)

                    // 💥 Clamp total impulse magnitude to prevent too strong throws
                    let maxImpulseMagnitude: Float = 0.00055  // adjust this if needed
                    let magnitude = simd_length(impulse)
                    if magnitude > maxImpulseMagnitude {
                        impulse = simd_normalize(impulse) * maxImpulseMagnitude
                    }
                    await physicsEntity.applyImpulse(impulse, at: .zero, relativeTo: nil)
                }
            }
        } catch let error {
            fatalError("\(error)")
        }
    }

    func discardRoll(for target: TargetNode) {
        guard let index = result.firstIndex(of: target.yootRoll) else {
            return
        }
        result.remove(at: index)
    }

    func checkForLanding() {
        guard shouldStartCheckingForLanding else { return }
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
            let upsideDownCount = yootEntities.filter { isEntityUpsideDown($0) }.count

            let rollResult = Yoot(rawValue: upsideDownCount) ?? .doe
            if rollResult.canThrowAgain {
                delegate?.yootRollDidRollDouble()
            }
            result.append(rollResult)
            delegate?.yootRollDidFinishRoll()
        }

        wasMoving = currentlyMoving
    }
}

private extension YootRollManager {
    func loadYootEntities() throws {
        guard let yootThrowBoard else {
            throw YootRollError.yootBoardNotFound
        }

        for yoot in Constants.yootEntityNames {
            guard let yootEntity = yootThrowBoard.findEntity(named: yoot) else {
                throw YootRollError.yootEntityNotFound
            }
            yootEntities.append(yootEntity)
            // Store the original transform
            originalTransforms[yoot] = yootEntity.transform
        }
    }

    func isEntityUpsideDown(_ entity: Entity) -> Bool {
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

        // Tolerance threshold — adjust if needed
        if dotProduct < -0.7 {
            return true // upside down
        } else {
            return false // upright or sideways
        }
    }

    func resetToOriginalPosition() {
        for yoot in yootEntities {
            if let original = originalTransforms[yoot.name] {
                // Reset position
                yoot.transform = original

                // Reset physics
                if let physics = yoot as? (Entity & HasPhysicsBody & HasPhysicsMotion) {
                    physics.physicsMotion?.linearVelocity = .zero
                    physics.physicsMotion?.angularVelocity = .zero
                }

                // Randomly flip face down (rotate 180° around X)
                let shouldFaceDown = Bool.random()
                if shouldFaceDown {
                    let flipRotation = simd_quatf(angle: .pi, axis: SIMD3<Float>(1, 0, 0))
                    yoot.orientation *= flipRotation
                }
            }
        }
    }

}
