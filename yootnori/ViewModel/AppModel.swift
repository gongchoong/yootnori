//
//  AppModel.swift
//  yootnori
//
//  Created by David Lee on 9/21/24.
//

import SwiftUI
import RealityKit
import RealityKitContent

enum SelectedMarker: Equatable {
    case new
    case existing(Entity)
    case none
}

@MainActor
class AppModel: ObservableObject {
    private(set) var rootEntity = Entity()
    private let nodeMap = NodeMap()

    private var markerMap: MarkerMap

    @State var markersToGo: Int = 4
    @Published var selectedMarker: SelectedMarker = .none
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
    
    func discardRoll(for target: TargetNode) {
        rollResult = rollResult.filter { $0 != target.yootRoll }
    }
}

// MARK: Button tap
extension AppModel {
    func pressedRollButton() async {
        await roll()
    }

    func pressedNewMarkerButton() {
        clearAllTargetNodes()
        switch selectedMarker {
        case .existing, .none:
            if case .existing(let entity) = selectedMarker {
                Task { @MainActor in
                    await drop(entity: entity)
                }
            }
            selectedMarker = .new
            updateTargetNodes()
        case .new:
            selectedMarker = .none
        }
    }
}

// MARK: Calculations
extension AppModel {
    // Retrieve the names of all possible nodes where a marker can be placed based on the outcome of each Yoot roll.
    func updateTargetNodes(starting: NodeName = .bottomRightVertex) {
        func step(
            starting: NodeName,
            name: NodeName,
            yootRoll: Yoot,
            remainingSteps: Int,
            destination: inout Set<TargetNode>
        ) {
            guard remainingSteps > 0 else {
                destination.insert(TargetNode(name: name, yootRoll: yootRoll))
                return
            }
            var nextNodes = nodeMap.getNext(name: name)
            
            // inner nodes should only be reachable from vertex nodes
//            nextNodes = nextNodes.filter({ nodeName in
//                return nodeName.isInnerNode ? starting.isVertex : true
//            })

            guard !nextNodes.isEmpty else { return }
            for nextNode in nextNodes {
                step(
                    starting: starting,
                    name: nextNode,
                    yootRoll: yootRoll,
                    remainingSteps: remainingSteps - 1,
                    destination: &destination
                )
            }
        }

        var targetNodes = Set<TargetNode>()
        for yootRoll in self.rollResult {
            step(
                starting: starting,
                name: starting,
                yootRoll: yootRoll,
                remainingSteps: yootRoll.steps,
                destination: &targetNodes
            )
        }
        self.targetNodes = targetNodes
    }
    
    func getTargetNode(nodeName: NodeName) -> TargetNode? {
        targetNodes.filter({ $0.name == nodeName }).first
    }
    
    func clearAllTargetNodes() {
        self.targetNodes.removeAll()
    }
}

extension AppModel {
    func perform(action: Action) {
        switch action {
        case .tapMarker(let entity):
            selectedMarker = .existing(entity)
            guard let node = getNode(from: entity) else { return }
            updateTargetNodes(starting: node.name)
            Task { @MainActor in
                await elevate(entity: entity)
            }
        case .tapTile(let node):
            guard let targetNode = getTargetNode(nodeName: node.name) else { return }
            defer {
                discardRoll(for: targetNode)
                clearAllTargetNodes()
                selectedMarker = .none
            }

            switch selectedMarker {
            case .new:
                // Create a new marker.
                Task { @MainActor in
                    try await create(at: node)
                }
            case .existing(let entity):
                // Move selected marker to the selected tile.
                Task { @MainActor in
                    print("Move existing marker \(entity)")
                    await move(entity: entity, to: node)
                }
            case .none:
                break
            }
        }
    }

    private func create(at node: Node) async throws {
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
            updateMarkerMap(node: node, entity: entity)
        } catch {
            fatalError("Failed to create a new marker at \(node.index)")
        }
    }
    
    private func move(entity marker: Entity, to node: Node) async {
        func step(entity marker: Entity, to node: Node) {
            guard let currentNode = getNode(from: marker), let currentNodeDetail = nodeMap.getNodeDetail(from: currentNode) else { return }
        }
        do {
            // get current node where marker is at
            // get the next node from markermap using marker
            // move marker to the next node
            // find next node
            // continue until next node == node
            
            let duration: TimeInterval = 3
            let newPosition = try node.index.position()
            var translation = marker.position
            translation = newPosition
            marker.move(
                to: .init(
                    translation: translation
                ),
                relativeTo: self.rootEntity,
                duration: duration
            )
            updateMarkerMap(node: node, entity: marker)
            try? await Task.sleep(for: .seconds(duration))
        } catch {
            fatalError("Failed to move selected marker to \(node.index)")
        }
    }

    private func elevate(entity marker: Entity) async {
        do {
            var translation = marker.position
            translation.z = Dimensions.Marker.elevated
            let duration: TimeInterval = 0.6
            marker.move(to: .init(translation: translation),
                                 relativeTo: self.rootEntity,
                                 duration: duration)
            try? await Task.sleep(for: .seconds(duration))
        }
    }
    
    private func drop(entity marker: Entity) async {
        do {
            var translation = marker.position
            translation.z = Dimensions.Marker.dropped
            let duration: TimeInterval = 0.6
            marker.move(to: .init(translation: translation),
                                 relativeTo: self.rootEntity,
                                 duration: duration)
            try? await Task.sleep(for: .seconds(duration))
        }
    }
}

// MARK: Marker Map
private extension AppModel {
    func updateMarkerMap(node: Node, entity: Entity) {
        markerMap.update(node: node, entity: entity)
    }
    
    func getNode(from entity: Entity) -> Node? {
        markerMap.getNode(from: entity)
    }
}
