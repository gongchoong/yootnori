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

protocol RollViewModel: ObservableObject {
    func roll() async
    func discardRoll(for target: TargetNode)
    func checkForLanding()
    var delegate: RollViewModelDelegate? { get set }
    var result: [Yoot] { get set }
    var resultPublisher: Published<[Yoot]>.Publisher { get }
    var yootThrowBoard: Entity? { get set }
}

protocol RollViewModelDelegate {
    func rollViewModelDidStartRoll()
    func rollViewModelDidFinishRoll()
    func rollViewModelDidDetectDouble()
}

class ThrowViewModel: RollViewModel, ObservableObject {
    enum Constants {
        static var yootEntityNames: [String] = ["yoot_1", "yoot_2", "yoot_3", "yoot_4"]
        static var xOffset: Float = 0.00005
        static var yOffset: Float = 0.00045
        static var zOffset: Float = 0.00005
    }

    enum YootError: Error {
        case yootBoardNotFound
        case yootEntityNotFound
    }

    var yootThrowBoard: Entity?
    var delegate: RollViewModelDelegate?
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
        delegate?.rollViewModelDidStartRoll()
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
                    let impulse = SIMD3<Float>(randomX, Constants.yOffset, randomZ)
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
                delegate?.rollViewModelDidDetectDouble()
            }
            result.append(rollResult)
            delegate?.rollViewModelDidFinishRoll()
        }

        wasMoving = currentlyMoving
    }
}

private extension ThrowViewModel {
    func loadYootEntities() throws {
        guard let yootThrowBoard else {
            throw YootError.yootBoardNotFound
        }

        for yoot in Constants.yootEntityNames {
            guard let yootEntity = yootThrowBoard.findEntity(named: yoot) else {
                throw YootError.yootEntityNotFound
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
                yoot.transform = original
                // Also reset velocities if you’re using physics
                if let physics = yoot as? (Entity & HasPhysicsBody & HasPhysicsMotion) {
                    physics.physicsMotion?.linearVelocity = .zero
                    physics.physicsMotion?.angularVelocity = .zero
                }
            }
        }
    }

}
