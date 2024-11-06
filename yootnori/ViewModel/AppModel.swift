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
    @Published var rollResult: [Yoot] = []
    @Published var targetNodes = Set<TargetNode>()

    var canRollOnceMore: Bool = false

    init() {
        generateMarkerMap()
    }
}

extension AppModel {
    var hasRemainingRoll: Bool {
        !rollResult.isEmpty && !canRollOnceMore
    }
    
    var yootRollSteps: [String] {
        return rollResult.map { "\($0.steps)" }
    }
}

// MARK: Yoot roll
private extension AppModel {
    func roll() async {
        var result: Yoot
        canRollOnceMore = false
        switch Int.random(in: 1...5) {
        case 1: result = .doe
        case 2: result = .gae
        case 3: result = .gull
        case 4:
            result = .yoot
            canRollOnceMore = true
        case 5:
            result = .mo
            canRollOnceMore = true
        default:
            result = .doe
        }

        rollResult.append(result)
    }
    
    func discardRollFor(target: TargetNode) {
        rollResult = rollResult.filter { $0 != target.yootRoll }
    }
}

// MARK: Button tap
extension AppModel {
    func pressedRollButton() async {
        await roll()
    }

    func pressedNewMarkerButton() {
        self.newMarkerSelected = true
        self.updateTargetNodes()
    }
}

// MARK: Calculations
extension AppModel {
    // Retrieve the names of all possible nodes where a marker can be placed based on the outcome of each Yoot roll.
    func updateTargetNodes(starting: NodeName = .bottomRightVertex) {
        func step(name: NodeName, yootRoll: Yoot, remainingSteps: Int, destination: inout Set<TargetNode>) {
            guard remainingSteps > 0 else {
                destination.insert(TargetNode(name: name, yootRoll: yootRoll))
                return
            }
            let nextNodes = nodeMap.getNext(name: name)
            guard !nextNodes.isEmpty else { return }
            for nextNode in nextNodes {
                step(name: nextNode, yootRoll: yootRoll, remainingSteps: remainingSteps - 1, destination: &destination)
            }
        }

        var targetNodes = Set<TargetNode>()
        for yootRoll in self.rollResult {
            step(name: starting, yootRoll: yootRoll, remainingSteps: yootRoll.steps, destination: &targetNodes)
        }
        self.targetNodes = targetNodes
    }
    
    func getTargetNode(nodeName: NodeName) -> TargetNode? {
        targetNodes.filter({ $0.name == nodeName }).first
    }
    
    func clearTargetNodes() {
        self.targetNodes.removeAll()
    }
}

extension AppModel {
    func perform(node: Node) {
        guard let targetNode = getTargetNode(nodeName: node.name) else { return }
        defer {
            updateMarkerMap(node: node)
            discardRollFor(target: targetNode)
            clearTargetNodes()
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
        print("Marker updated \(markerMap)")
    }

    func hasMarker(on node: Node) -> Bool {
        guard let markerCounter = markerMap[node.name] else {
            fatalError("markerMap should have markerCount per every node name")
        }
        return markerCounter > 0
    }
}
