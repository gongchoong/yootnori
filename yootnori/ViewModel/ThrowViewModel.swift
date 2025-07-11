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

protocol RollViewModel {
    func roll()
    func discardRoll(for target: TargetNode)
    func checkForLanding()
    var resultPublisher: Published<[Yoot]>.Publisher { get }
    var isAnimatingPublisher: Published<Bool>.Publisher { get }
    var hasRemainingRollPublisher: AnyPublisher<Bool, Never> { get }
    var shouldStartCheckingForLanding: Bool { get }
    var yootThrowBoard: Entity? { get set }
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
    var yootEntities: [Entity] = []
    private var originalTransforms: [String: Transform] = [:]

    @Published var wasMoving = false
    @Published var landed = false

    @Published var isAnimating = false
    var isAnimatingPublisher: Published<Bool>.Publisher { $isAnimating }
    @Published var result: [Yoot] = []
    var resultPublisher: Published<[Yoot]>.Publisher { $result }
    @Published var canThrowAgain: Bool = false
    var hasRemainingRollPublisher: AnyPublisher<Bool, Never> {
        Publishers.CombineLatest($result, $canThrowAgain)
            .map { !$0.0.isEmpty && !$0.1 }
            .eraseToAnyPublisher()
    }

    var allEntitiesMoving: Bool {
        yootEntities.allSatisfy({ $0.isMoving() })
    }

    var shouldStartCheckingForLanding: Bool {
        guard isAnimating, !landed, wasMoving || allEntitiesMoving else { return false }
        return true
    }

    func roll() {
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
                    physicsEntity.applyImpulse(impulse, at: .zero, relativeTo: nil)
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

            // Use the rawValue initializer for mapping
            guard let yootResult = Yoot(rawValue: upsideDownCount) else {
                result.append(.doe)
                return
            }

            result.append(yootResult)
            canThrowAgain = yootResult.canThrowAgain
            isAnimating = false
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
