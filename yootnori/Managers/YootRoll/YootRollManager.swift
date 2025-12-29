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

@MainActor
protocol YootRollDelegate: AnyObject {
    /// Called when a roll animation or logic begins.
    func yootRollDidStartRoll() throws

    /// Called when a roll completes without any detailed result.
    func yootRollDidFinishRoll() throws

    /// Called when a roll completes with resolved results.
    /// - Parameters:
    ///   - buffer: The sequence of throw frames that occurred during the roll.
    ///   - result: The final `Yoot` result of the roll.
    func yootRollDidFinishRoll(with buffer: [ThrowFrame], result: Yoot) throws
}

class YootRollManager: ObservableObject {
    enum YootRollError: Error {
        case yootBoardNotFound
        case yootEntityNotFound
        case unableToDiscardRoll
    }

    enum Constants {
        static var yootEntityNames: [String] = ["yoot_1", "yoot_2", "yoot_3", "yoot_4"]
        static var xOffset: Float = 0.00005
        static var yOffset: Float = 0.0004
        static var zOffset: Float = 0.00005
    }

    weak var yootThrowBoard: Entity?
    weak var delegate: YootRollDelegate?
    var yootEntities: [Entity] = []

    @Published var result: [Yoot] = [] {
        didSet {
            if let newYoot = result.last {
                print("New Yoot result added: \(newYoot)")
                // You can perform additional logic here if needed
            }
        }
    }

    private var originalTransforms: [String: Transform] = [:]
    private var wasMoving = false
    private var landed = false
    private var isAnimating = false

    // Recording buffer (host only)
    private var currentThrowID: UUID?
    private var frameBuffer: [ThrowFrame] = []
    private var isRecording: Bool = false
    private var lastRecordTime: TimeInterval = 0

    private var allEntitiesMoving: Bool {
        yootEntities.allSatisfy({ $0.isMoving() })
    }

    private var shouldStartCheckingForLanding: Bool {
        guard isAnimating, !landed, wasMoving || allEntitiesMoving else { return false }
        return true
    }

    private var upsideDownCount: Int {
        yootEntities.filter { isEntityUpsideDown($0) }.count
    }

    func roll() async throws {
        // Find yoot entities from the YootThrowBoard entity
        if yootEntities.isEmpty {
            try loadYootEntities()
        }

        try await delegate?.yootRollDidStartRoll()

        landed = false
        isAnimating = true

        startRecording()

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
    }

    @MainActor func checkForLanding() throws {
        guard shouldStartCheckingForLanding else { return }
        var currentlyMoving = false

        recordFrameSample()

        for yoot in yootEntities {
            if yoot.isMoving() {
                currentlyMoving = true
                break
            }
        }

        // Detect landing (transition from moving to stopped)
        if wasMoving && !currentlyMoving && !landed {
            landed = true

            let rollResult = Yoot(rawValue: upsideDownCount) ?? .doe
            result.append(rollResult)

            endRecording()
            try delegate?.yootRollDidFinishRoll(with: frameBuffer, result: rollResult)
        }

        wasMoving = currentlyMoving
    }

    func discardRoll(for target: TargetNode) throws {
        guard let index = result.firstIndex(of: target.yootRoll) else {
            throw YootRollError.unableToDiscardRoll
        }
        result.remove(at: index)
        print("Roll discarded in YootRollManager \(result)")
    }
}

// MARK: - Internal Helpers
// Contains private utility functions used within YootRollManager for loading entities,
// handling physics and orientation, and resetting state before each throw.
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

                randomlyFlipFaceDown(yoot)
            }
        }
    }

    func randomlyFlipFaceDown(_ yoot: Entity) {
        // Randomly flip face down (rotate 180° around X)
        let shouldFaceDown = Bool.random()
        if shouldFaceDown {
            let flipRotation = simd_quatf(angle: .pi, axis: SIMD3<Float>(1, 0, 0))
            yoot.orientation *= flipRotation
        }
    }
}

// MARK: - Recording & Replay
// Manages throw recording and playback for SharePlay synchronization.
// Includes frame sampling during physics simulation and interpolated frame-based animation for replays.
extension YootRollManager {
    func startRecording() {
        frameBuffer.removeAll()
        isRecording = true
        currentThrowID = UUID()
    }

    func endRecording() {
        isRecording = false
    }

    func recordFrameSample() {
        guard isRecording else { return }

        let now = ProcessInfo.processInfo.systemUptime
        let delta = now - lastRecordTime

        // Only record if at least 0.066s (~15 FPS) has passed
        guard delta > 0.066 else { return }

        lastRecordTime = now

        let transforms = yootEntities.map { YootRollTransformData($0.transform) }
        let frame = ThrowFrame(timestamp: now, yootTransforms: transforms)
        frameBuffer.append(frame)
    }

/// Non-host peers call this when they receive a replay package from SharePlay
    @MainActor
    func replayThrowFromNetwork(bufferFrame: [ThrowFrame]) async throws {
        try delegate?.yootRollDidStartRoll()
        // Play back the captured frames
        try await playFrameSequence(bufferFrame: bufferFrame)
        try delegate?.yootRollDidFinishRoll()
    }

    @MainActor
    func playFrameSequence(bufferFrame: [ThrowFrame]) async throws {
        if yootEntities.isEmpty {
            try loadYootEntities()
        }

        // Assume frames are sorted by timestamp ascending
        for i in 0..<(bufferFrame.count - 1) {
            let f0 = bufferFrame[i]
            let f1 = bufferFrame[i+1]

            // How long between these two samples (in seconds)
            let segmentDuration = max(f1.timestamp - f0.timestamp, 0.016)

            // We'll substep this segment
            let steps = max(Int(segmentDuration / 0.016), 1)
            for step in 0..<steps {
                let t = Float(step + 1) / Float(steps)

                // Apply interpolated transforms for each yoot
                for (yootIndex, yoot) in yootEntities.enumerated() {
                    let t0 = f0.yootTransforms[yootIndex].asTransform()
                    let t1 = f1.yootTransforms[yootIndex].asTransform()
                    let interp = interpolateTransform(t0, t1, t: t)
                    yoot.transform = interp
                }

                // wait ~1 frame
                try? await Task.sleep(nanoseconds: 16_000_000)
            }
        }
    }

    func interpolateTransform(_ a: Transform, _ b: Transform, t: Float) -> Transform {
        let pos = simd_mix(a.translation, b.translation, SIMD3<Float>(repeating: t))
        let rot = simd_slerp(a.rotation, b.rotation, t)
        let scl = simd_mix(a.scale, b.scale, SIMD3<Float>(repeating: t))
        return Transform(scale: scl, rotation: rot, translation: pos)
    }
}
