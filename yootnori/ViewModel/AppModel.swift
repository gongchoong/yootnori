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

    private var markerMap: MarkerMap

    @State var markersToGo: Int = 4
    @Published var newMarkerSelected: Bool = false
    @Published var rollResult: [Yoot] = []
    @Published var targetNodes = Set<TargetNode>()

    var canRollOnceMore: Bool = false

    init() {
        markerMap = MarkerMap()
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
    func perform(action: Action) {
        switch action {
        case .tapMarker(let entity):
            let node = markerMap.getNode(from: entity)
            print(node)
        case .tapTile(let node):
            // Create a new node
            Task { @MainActor in
                try await createNewMarker(at: node)
            }
        }
    }

    @MainActor
    func createNewMarker(at node: Node) async throws {
        guard let targetNode = getTargetNode(nodeName: node.name) else { return }
        defer {
            discardRollFor(target: targetNode)
            clearTargetNodes()
        }

        do {
            let position = try node.index.position()
            let entity = try await Entity(named: "Scene", in: RealityKitContent.realityKitContentBundle)
            entity.position = position
            entity.components.set([
                CollisionComponent(shapes: [{
                    .generateBox(size: entity.visualBounds(relativeTo: nil).extents)
                }()]),
                InputTargetComponent(),
                MarkerComponent(nodeName: node.name.rawValue)
            ])
            self.rootEntity.addChild(entity)
            markerMap.update(node: node, entity: entity)
        } catch {
            fatalError("Failed to move marker to \(node.index)")
        }
    }
}
