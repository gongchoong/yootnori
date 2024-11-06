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
    private let nodeMap = NodeMap()

    var markerMap: [NodeName: Int] = [:]

    @State var markersToGo: Int = 4
    @Published var newMarkerSelected: Bool = false
    @Published var yootRoll: [Yoot] = []
    @Published var destinationNodes = Set<NodeName>()

    init() {
        generateMarkerMap()
    }

    func pressedRollButton() async {
        await roll()
    }
}

extension AppModel {
    var canPlayMarker: Bool {
        !yootRoll.isEmpty
    }
    
    var yootRollSteps: [String] {
        return yootRoll.map { "\($0.steps)" }
    }
}

// MARK: Yoot roll
extension AppModel {
    func roll() async {
        var result: Yoot
        switch Int.random(in: 1...5) {
        case 1: result = .doe
        case 2: result = .gae
        case 3: result = .gull
        case 4: result = .yoot
        case 5: result = .mo
        default:
            result = .doe
        }

//        switch result {
//        case .doe:
//            print("yootRoll: \(String(describing: result)), steps: \(Yoot.doe.steps))")
//        case .gae:
//            print("yootRoll: \(String(describing: result)), steps: \(Yoot.gae.steps))")
//        case .gull:
//            print("yootRoll: \(String(describing: result)), steps: \(Yoot.gull.steps))")
//        case .yoot:
//            print("yootRoll: \(String(describing: result)), steps: \(Yoot.yoot.steps))")
//        case .mo:
//            print("yootRoll: \(String(describing: result)), steps: \(Yoot.mo.steps))")
//        }

        yootRoll.append(result)
    }
}

// MARK: Button tap
extension AppModel {
    func pressedNewMarkerButton() {
        newMarkerSelected.toggle()
        destinationNodes = getDestinationNodes()
    }
}

// MARK: Calculations
extension AppModel {
    // Retrieve the names of all possible nodes where a marker can be placed based on the outcome of each Yoot roll.
    func getDestinationNodes(starting: NodeName = .bottomRightVertex) -> Set<NodeName> {
        func step(node: NodeName, remainingSteps: Int, destination: inout Set<NodeName>) {
            guard remainingSteps > 0 else {
                destination.insert(node)
                return
            }
            let nextNodes = nodeMap.getNextNodes(name: node)
            guard !nextNodes.isEmpty else { return }
            for nextNode in nextNodes {
                step(node: nextNode, remainingSteps: remainingSteps - 1, destination: &destination)
            }
        }

        var destinationNodes = Set<NodeName>()
        for yootRoll in self.yootRoll {
            step(node: starting, remainingSteps: yootRoll.steps, destination: &destinationNodes)
        }
        return destinationNodes
    }
}

extension AppModel {
    func perform(node: Node) {
        defer {
            updateMarkerMap(node: node)
        }
        Task { @MainActor in
            do {
                try await createMarker(at: node)
            } catch {
                fatalError("Failed to move marker to \(node.index)")
            }
        }
    }

    @MainActor
    func createMarker(at node: Node) async throws {
        do {
            let position = try node.index.position()
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

// MARK: MarkerMap
extension AppModel {
    func generateMarkerMap() {
        for nodeName in NodeName.allCases {
            markerMap[nodeName] = 0
        }
    }

    func updateMarkerMap(node: Node) {
        guard let markerCount = markerMap[node.name] else {
            return
        }
        markerMap[node.name] = markerCount + 1
    }

    func hasMarker(on node: Node) -> Bool {
        guard let markerCounter = markerMap[node.name] else {
            fatalError("markerMap should have markerCount per every node name")
        }
        return markerCounter > 0
    }
}
