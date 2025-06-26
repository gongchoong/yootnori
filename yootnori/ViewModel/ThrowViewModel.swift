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
    var hasRemainingRoll: Bool { get }
    var shouldStartCheckingForLanding: Bool { get }
    var yootThrowBoard: Entity? { get set }
}

class ThrowViewModel: RollViewModel, ObservableObject {
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
    @Published var isAnimating = false
    var isAnimatingPublisher: Published<Bool>.Publisher { $isAnimating }
    @Published var landed = false
    @Published var result: [Yoot] = []
    var resultPublisher: Published<[Yoot]>.Publisher { $result }

    var yootThrowBoard: Entity?
    var yootEntities: [Entity] = []
    var canRollAgain: Bool = false

    var hasRemainingRoll: Bool {
        !result.isEmpty && !canRollAgain
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

        for yoot in Constants.yoots {
            guard let yootEntity = yootThrowBoard.findEntity(named: yoot) else {
                throw YootError.yootEntityNotFound
            }
            yootEntities.append(yootEntity)
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

        print("\(entity.name) dot product: \(dotProduct)")

        // Tolerance threshold — adjust if needed
        if dotProduct < -0.7 {
            print("🚫 \(entity.name) is upside down!")
            return true // upside down
        } else {
            print("✅ \(entity.name) landed upright.")
            return false // upright or sideways
        }
    }
}
