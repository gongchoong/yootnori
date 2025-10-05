//
//  Entity+Extensions.swift
//  yootnori
//
//  Created by David Lee on 11/10/24.
//

import Foundation
import RealityKit

extension Entity {
    static var empty: Entity {
        return Entity()
    }

    func isMoving() -> Bool {
        let velocityThreshold: Float = 0.01

        if let motionComponent = components[PhysicsMotionComponent.self] {
            let velocity = motionComponent.linearVelocity
            let speed = sqrt(velocity.x * velocity.x + velocity.y * velocity.y + velocity.z * velocity.z)
            return speed > velocityThreshold
        }
        return false
    }
}
