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
    private let nodeMap: NodeMap

    @State var markersToGo: Int = 4
    @Published var selectedMarker: SelectedMarker = .none
    @Published var rollResult: [Yoot] = []
    @Published var targetNodes = Set<TargetNode>()
    @Published var attachmentsProvider = AttachmentsProvider()
    @Published var isLoading: Bool = false

    var canRollOnceMore: Bool = false

    init() {
        self.nodeMap = NodeMap()
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
        guard let index = rollResult.firstIndex(of: target.yootRoll) else {
            return
        }
        rollResult.remove(at: index)
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
            from: NodeName,
            to: NodeName,
            yootRoll: Yoot,
            remainingSteps: Int,
            destination: inout Set<TargetNode>
        ) {
            guard remainingSteps > 0 else {
                destination.insert(TargetNode(name: to, yootRoll: yootRoll))
                return
            }
            var nextNodes = nodeMap.getNext(from: to)
            filter(nextNodes: &nextNodes)

            guard !nextNodes.isEmpty else { return }
            for nextNode in nextNodes {
                step(
                    from: starting,
                    to: nextNode,
                    yootRoll: yootRoll,
                    remainingSteps: remainingSteps - 1,
                    destination: &destination
                )
            }
        }

        func filter(nextNodes: inout [NodeName]) {
            // Inner nodes can only be reached if starting node is topRightVertex, topLeftVertex, or inner node
            nextNodes = nextNodes.filter({ node in
                node.isInnerNode ? starting.isInnerNode || starting == .topRightVertex || starting == .topLeftVertex : true
            })

            // If starting node is topRightVertex, or topLeftVertex, marker can only travel towards inner nodes.
            nextNodes = nextNodes.filter({ node in
                starting.isTopVertexNode ? node.isInnerNode : true
            })

            // If starting node is topRightVertex, or topRightDiagonals, marker cannot travel
            // towards the bottomRightDiagonal nodes.
            nextNodes = nextNodes.filter({ node in
                starting == .topRightVertex || starting.isTopRightDiagonalNode ? !node.isBottomRightDiagonalNode : true
            })

            // If starting node is topLeftVertex, or topLeftDiagonals, marker cannot travel
            // towards the bottomLeftDiagonal nodes.
            nextNodes = nextNodes.filter({ node in
                starting == .topLeftVertex || starting.isTopLeftDiagonalNode ? !node.isBottomLeftDiagonalNode : true
            })

            // If starting node is center, marker cannot travel towards the bottomLeftDiagonal nodes.
            nextNodes = nextNodes.filter({ node in
                starting == .center ? !node.isBottomLeftDiagonalNode : true
            })
        }

        var targetNodes = Set<TargetNode>()
        for yootRoll in self.rollResult {
            step(
                from: starting,
                to: starting,
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
    
    private func findRoute(from start: Node, to destination: Node, visited: Set<Node> = []) -> [Node]? {
        // Check if we've already visited this node to prevent infinite loops
        guard !visited.contains(start) else { return nil }

        // Add the current node to the visited set.
        var newVisited = visited
        newVisited.insert(start)

        // If the start is the destination, return start.
        if start == destination {
            return [start]
        }

        // Recursively explore each next node
        for nextNodeName in start.next {
            guard let nextNode = nodeMap.getNode(from: nextNodeName) else { break }
            if let path = findRoute(from: nextNode, to: destination, visited: newVisited) {
                return [start] + path
            }
        }

        // If no path is found, return nil.
        return nil
    }
}

extension AppModel {
    func perform(action: Action) {
        switch action {
        case .tapMarker(let tapped):
            switch selectedMarker {
            case .existing(let moving):
                // If same marker is selected, unselect.
                if tapped == moving {
                    withLoadingState {
                        await self.drop(entity: tapped)
                    }
                    selectedMarker = .none
                    clearAllTargetNodes()
                } else {
                    // If different marker is selected, piggy back.
                    guard let starting = getNodeFromMap(from: moving) else { return }
                    guard let destination = getNodeFromMap(from: tapped) else { return }
                    guard let targetNode = self.getTargetNode(nodeName: destination.name) else { return }
                    self.discardRoll(for: targetNode)
                    self.clearAllTargetNodes()

                    withLoadingState {
                        // Move the marker to the destination, then piggy back.
                        await self.move(entity: moving, to: destination)
                        await self.piggyBack(tapped: tapped, moving: moving)
                        // Remove the moved marker, then update the marker map.
                        self.removeMarkerFromMap(at: starting)
                        self.removeChildFromRoot(entity: moving)
                        self.selectedMarker = .none
                    }
                }
            case .new:
                // Creating a new marker, but another marker exists on the selected tile.
                guard let destination = getNodeFromMap(from: tapped) else { return }
                guard let targetNode = self.getTargetNode(nodeName: destination.name) else { return }
                self.discardRoll(for: targetNode)
                self.clearAllTargetNodes()

                withLoadingState {
                    // Create a new marker at the start tile, move the new marker to the selected tile,
                    // then piggy back.
                    // Creating an entity just for the animation.
                    guard let startNode = self.getNodeFromSet(from: .bottomRightVertex) else { return }
                    let entity = try await self.create(at: startNode)
                    await self.move(entity: entity, to: destination, isNewEntity: true)

                    await self.piggyBack(tapped: tapped)
                    self.removeChildFromRoot(entity: entity)
                    self.selectedMarker = .none
                }
            case .none:
                // If no previously selected marker, then set the new marker as selected.
                withLoadingState {
                    await self.elevate(entity: tapped)
                }
                selectedMarker = .existing(tapped)
                guard let node = getNodeFromMap(from: tapped) else { return }
                updateTargetNodes(starting: node.name)
            }
        case .tapTile(let node):
            switch selectedMarker {
            case .new:
                // Create a new marker at start then move the marker to the selected tile.
                withLoadingState {
                    guard let start = self.getNodeFromSet(from: .bottomRightVertex) else { return }
                    let entity = try await self.create(at: start)
                    await self.move(entity: entity, to: node, isNewEntity: true)
                    self.addMarkerToMap(new: entity, node: node)
                }
            case .existing(let entity):
                // Move selected marker to the selected tile.
                withLoadingState {
                    await self.move(entity: entity, to: node)
                    self.updateMarkerToMap(marker: entity, destination: node)
                }
            case .none:
                break
            }
            guard let targetNode = getTargetNode(nodeName: node.name) else { return }
            discardRoll(for: targetNode)
            clearAllTargetNodes()
            selectedMarker = .none
        }
    }

    private func create(at node: Node) async throws -> Entity {
        do {
            let position = try node.index.position()
            let entity = try await Entity(named: "Scene", in: RealityKitContent.realityKitContentBundle)
            entity.position = position
            entity.components.set([
                CollisionComponent(shapes: [{
                    .generateBox(size: entity.visualBounds(relativeTo: nil).extents)
                }()]),
                InputTargetComponent(),
                MarkerComponent(level: 1)
            ])
            addChildToRoot(entity: entity)
            return entity
        } catch {
            fatalError("Failed to create a new marker at \(node.index)")
        }
    }
    
    private func move(entity marker: Entity, to node: Node, isNewEntity: Bool = false) async {
        func step(entity marker: Entity, to newNode: Node) async {
            do {
                try await advance(entity: marker, to: newNode, duration: Dimensions.Marker.duration)
                await drop(entity: marker, duration: Dimensions.Marker.duration)
            } catch {
                fatalError("Failed to move selected marker to \(newNode.index)")
            }
        }

        // get route from current node to the destination node
        guard let currentNode = isNewEntity ? getNodeFromSet(from: .bottomRightVertex) : getNodeFromMap(from: marker) else { return }
        guard var route = findRoute(from: currentNode, to: node) else { return }
        // exclute the starting node
        route = route.filter { $0.name != currentNode.name }

        for routeNode in route {
            await step(entity: marker, to: routeNode)
        }
    }

    private func piggyBack(tapped: Entity, moving: Entity? = nil) async {
        guard let movingMarker = moving else {
            incrementLevel(tapped: tapped)
            printMap()
            return
        }
        addLevel(tapped: tapped, moving: movingMarker)
        printMap()
    }

    private func incrementLevel(tapped: Entity) {
        guard var tappedMarkerComponent = tapped.components[MarkerComponent.self] else { return }
        tappedMarkerComponent.level += 1
        tapped.components[MarkerComponent.self] = tappedMarkerComponent
        attachmentsProvider.attachments[tapped.id] = AnyView(MarkerLevelView(tapAction: { [weak self] in
            guard let self = self else { return }
            if self.hasRemainingRoll {
                self.perform(action: .tapMarker(tapped))
            }
        }, level: tappedMarkerComponent.level))
    }

    private func addLevel(tapped: Entity, moving: Entity) {
        guard var tappedMarkerComponent = tapped.components[MarkerComponent.self] else { return }
        guard let movingMarkerComponent = moving.components[MarkerComponent.self] else { return }
        tappedMarkerComponent.level += movingMarkerComponent.level
        tapped.components[MarkerComponent.self] = tappedMarkerComponent
        attachmentsProvider.attachments[tapped.id] = AnyView(MarkerLevelView(tapAction: { [weak self] in
            guard let self = self else { return }
            if self.hasRemainingRoll {
                self.perform(action: .tapMarker(tapped))
            }
        }, level: tappedMarkerComponent.level))
    }
}

// MARK: Marker animation

private extension AppModel {
    func advance(entity marker: Entity, to node: Node, duration: CGFloat) async throws {
        let newPosition = try node.index.position()
        var translation = marker.position
        translation = newPosition
        translation.z = Dimensions.Marker.elevated
        marker.move(
            to: .init(
                translation: translation
            ),
            relativeTo: self.rootEntity,
            duration: duration
        )
        try? await Task.sleep(for: .seconds(duration))
    }

    func elevate(entity marker: Entity, duration: CGFloat = 0.6) async {
        do {
            var translation = marker.position
            translation.z = Dimensions.Marker.elevated
            marker.move(to: .init(translation: translation),
                                 relativeTo: self.rootEntity,
                                 duration: duration)
            try? await Task.sleep(for: .seconds(duration))
        }
    }
    
    func drop(entity marker: Entity, duration: CGFloat = 0.6) async {
        do {
            var translation = marker.position
            translation.z = Dimensions.Marker.dropped
            marker.move(to: .init(translation: translation),
                                 relativeTo: self.rootEntity,
                                 duration: duration)
            try? await Task.sleep(for: .seconds(duration))
        }
    }
}

// MARK: Marker Map
private extension AppModel {
    func addMarkerToMap(new marker: Entity, node: Node) {
        nodeMap.create(marker: marker, node: node)
    }

    func updateMarkerToMap(marker: Entity, destination node: Node) {
        nodeMap.update(marker: marker, node: node)
    }

    func removeMarkerFromMap(at node: Node) {
        nodeMap.remove(node: node)
    }

    func getNodeFromMap(from marker: Entity) -> Node? {
        nodeMap.getNode(from: marker)
    }
}

// MARK: NodeMap
extension AppModel {
    func getNodeFromSet(from nodeName: NodeName) -> Node? {
        nodeMap.getNode(from: nodeName)
    }
}

private extension AppModel {
    func addChildToRoot(entity: Entity) {
        rootEntity.addChild(entity)
    }

    func removeChildFromRoot(entity: Entity) {
        rootEntity.removeChild(entity)
    }
}

private extension AppModel {
    func withLoadingState(operation: @escaping () async throws -> Void) {
        Task { @MainActor in
            isLoading = true
            do {
                try await operation()
            } catch {
                print("error occured in withLoadingState")
            }
            isLoading = false
        }
    }
}
