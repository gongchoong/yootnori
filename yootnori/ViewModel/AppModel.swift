//
//  AppModel.swift
//  yootnori
//
//  Created by David Lee on 9/21/24.
//

import SwiftUI
import RealityKit
import RealityKitContent

@MainActor
class AppModel: ObservableObject {
    private(set) var rootEntity = Entity()
    @State var markersToGo: Int = 4
    @Published var newMarkerSelected: Bool = false
    @Published var yootRoll: Yoot?
    
    init() {
        
    }

    func roll() {
        switch Int.random(in: 1...5) {
        case 1: yootRoll = .doe()
        case 2: yootRoll = .gae()
        case 3: yootRoll = .gull()
        case 4: yootRoll = .yoot()
        case 5: yootRoll = .mo()
        default:
            yootRoll = nil
        }
        switch yootRoll {
        case .doe(let steps):
            print("yootRoll: \(String(describing: yootRoll)), steps: \(steps))")
        case .gae(let steps):
            print("yootRoll: \(String(describing: yootRoll)), steps: \(steps))")
        case .gull(let steps):
            print("yootRoll: \(String(describing: yootRoll)), steps: \(steps))")
        case .yoot(let steps):
            print("yootRoll: \(String(describing: yootRoll)), steps: \(steps))")
        case .mo(let steps):
            print("yootRoll: \(String(describing: yootRoll)), steps: \(steps))")
        case nil:
            return
        }
    }

    func canPlayNewMarker() -> Bool {
        return newMarkerSelected
    }
}

extension AppModel {
    func perform(index: Index) async throws {
        try await playMarker(index: index)
    }

    func playMarker(index: Index) async throws {
        Task { @MainActor in
            do {
                let position = try index.position()
                let entity = try await Entity(named: "Scene", in: RealityKitContent.realityKitContentBundle)
                let rotationAngle: Float = .pi / 2
                entity.transform.rotation = simd_quatf(angle: rotationAngle, axis: [1, 0, 0])
                entity.position = position
                entity.components.set([
                    CollisionComponent(shapes: [{
                        var value: ShapeResource = .generateBox(size: entity.visualBounds(relativeTo: nil).extents)
                        value = value.offsetBy(translation: [0, value.bounds.extents.y / 2, 0])
                        return value
                    }()]),
                    InputTargetComponent()
                ])
                self.rootEntity.addChild(entity)
            } catch {
                throw error
            }
        }
    }
}
