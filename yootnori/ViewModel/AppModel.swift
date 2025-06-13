//
//  AppModel.swift
//  yootnori
//
//  Created by David Lee on 9/21/24.
//

import SwiftUI
import RealityKit
import RealityKitContent
import Combine

enum SelectedMarker: Equatable {
    case new
    case existing(Entity)
    case none
}

@MainActor
class AppModel: ObservableObject {
    private(set) var rootEntity = Entity()
    private let rollViewModel: RollViewModel
    private var cancellables = Set<AnyCancellable>()
    private var nodes = Set<Node>()
    private var trackedMarkers: [Node: Entity] = [:] {
        didSet {
            print(self.trackedMarkers.keys.map { $0.name })
        }
    }

    @State var markersToGo: Int = 4
    @Published var selectedMarker: SelectedMarker = .none
    @Published var targetNodes = Set<TargetNode>()
    @Published var attachmentsProvider = AttachmentsProvider()
    @Published var isLoading: Bool = false
    @Published private(set) var rollResult: [Yoot] = []

    init(rollViewModel: RollViewModel = RollViewModel()) {
        self.rollViewModel = rollViewModel
        
        generateNodes()
        subscribe()
    }

    private func generateNodes() {
        nodes = Set(NodeConfig.nodeNames.map { name in
            guard let index = NodeConfig.nodeIndexMap[name], let relationShip = NodeConfig.nodeRelationships[name] else {
                return Node(name: .empty, index: Index.outer(column: 0, row: 0), next: [], prev: [])
            }
            return Node(name: name, index: index, next: relationShip.next, prev: relationShip.prev)
        })
    }
    
    private func subscribe() {
        rollViewModel.$result
            .receive(on: RunLoop.main)
            .assign(to: \.rollResult, on: self)
            .store(in: &cancellables)
    }
}

// MARK: Button tap
extension AppModel {
    func roll(yoot: Yoot) async {
        await rollViewModel.roll(yoot: yoot)
    }

    func handleNewMarkerTap() {
        clearAllTargetNodes()
        switch selectedMarker {
        case .existing, .none:
            // If a marker was already picked up, drop that marker.
            if case .existing(let entity) = selectedMarker {
                Task { @MainActor in
                    await drop(entity)
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
            next: NodeName,
            yootRoll: Yoot,
            remainingSteps: Int,
            destination: inout Set<TargetNode>
        ) {
            guard remainingSteps > 0 else {
                destination.insert(TargetNode(name: next, yootRoll: yootRoll))
                return
            }
            var nextNodes = nextNodeNames(from: next)
            filter(nextNodes: &nextNodes)

            guard !nextNodes.isEmpty else { return }
            for nextNode in nextNodes {
                step(
                    starting: starting,
                    next: nextNode,
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
                starting: starting,
                next: starting,
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

    /// Recursively finds a path from the `start` node to the `destination` node,
    /// considering visited nodes to prevent cycles and applying custom path rules
    /// (e.g., directional constraints when passing through `.center`).
    ///
    /// - Parameters:
    ///   - start: The current node being evaluated in the recursive search.
    ///   - destination: The target node we want to reach.
    ///   - startingPoint: The original starting node for determining conditional routes (e.g., center behavior).
    ///   - visited: A set of nodes already visited to avoid infinite loops.
    /// - Returns: An array representing the path from `start` to `destination`, or `nil` if no path is found.
    private func findRoute(from start: Node, to destination: Node, startingPoint: Node, visited: Set<Node> = []) -> [Node]? {
        // Check if we've already visited this node to prevent infinite loops
        guard !visited.contains(start) else { return nil }

        // Add the current node to the visited set.
        var newVisited = visited
        newVisited.insert(start)

        // If the start is the destination, return start.
        if start == destination {
            return [start]
        }

        // Get valid next steps
        let nextSteps = validNextNodes(for: start, startingFrom: startingPoint)

        // Recursively explore each next node
        for nextNodeName in nextSteps {
            guard let nextNode = findNode(named: nextNodeName) else { break }
            if let path = findRoute(from: nextNode, to: destination, startingPoint: startingPoint, visited: newVisited) {
                return [start] + path
            }
        }

        // If no path is found, return nil.
        return nil
    }

    /// Determines the valid next nodes to traverse from a given node,
    /// applying special routing logic when passing through the center node.
    ///
    /// - Parameters:
    ///   - node: The current node being evaluated.
    ///   - origin: The original starting node for the route.
    /// - Returns: A filtered list of next node names.
    ///   If the current node is `.center`, returns a single valid direction
    ///   based on the origin:
    ///     - From the top right path: only `.leftBottomDiagonal1`
    ///     - From the top left path: only `.rightBottomDiagonal1`
    private func validNextNodes(for node: Node, startingFrom origin: Node) -> [NodeName] {
        if node.name == .center {
            if [.topRightVertex, .rightTopDiagonal1, .rightTopDiagonal2].contains(origin.name) {
                return [.leftBottomDiagonal1]
            }
            if [.topLeftVertex, .leftTopDiagonal1, .leftTopDiagonal2].contains(origin.name) {
                return [.rightBottomDiagonal1]
            }
        }
        return node.next
    }
}

// Entity action
extension AppModel {
    func perform(action: Action) {
        switch action {
        // User tapped a marker on the board.
        case .tappedMarker(let destinationMarker):
            switch selectedMarker {
            case .existing(let sourceMarker):
                // Tapped the same marker again — just drop it to unselect.
                if destinationMarker == sourceMarker {
                    withLoadingState {
                        await self.drop(destinationMarker)
                    }
                } else {
                    // Tapped a different marker — time to piggyback.
                    guard let sourceNode = lookupNode(containing: sourceMarker) else { return }
                    guard let destinationNode = lookupNode(containing: destinationMarker) else { return }
                    // Ensure there's a valid target node for interaction resolution.
                    guard let targetNode = self.getTargetNode(nodeName: destinationNode.name) else { return }

                    // Clear out any previous state tied to rolls or targets.
                    self.discardRoll(for: targetNode)
                    self.clearAllTargetNodes()

                    withLoadingState {
                        // Move to the destination marker’s tile.
                        await self.move(sourceMarker, to: destinationNode)

                        // Ride on top of the tapped marker.
                        await self.piggyBack(rider: sourceMarker, carrier: destinationMarker)
                        self.detachMarker(from: sourceNode)
                    }
                }
            case .new:
                // Attempting to place a new marker, but tapped a marker that’s already on the board.
                guard let destinationNode = lookupNode(containing: destinationMarker) else { return }
                guard let targetNode = self.getTargetNode(nodeName: destinationNode.name) else { return }

                // Clear any lingering roll or target state before continuing.
                self.discardRoll(for: targetNode)
                self.clearAllTargetNodes()

                withLoadingState {
                    // Create a temporary marker at the START node and move it to the tapped tile.
                    // This is just for animation purposes.
                    guard let startNode = self.findNode(named: .bottomRightVertex) else { return }
                    let sourceMarker = try await self.create(at: startNode)
                    await self.move(sourceMarker, to: destinationNode)

                    // Piggyback onto the existing marker.
                    await self.piggyBack(rider: sourceMarker, carrier: destinationMarker)
                }
            case .none:
                // No marker was selected — now selecting the tapped existing marker on the board.
                withLoadingState {
                    await self.elevate(entity: destinationMarker)
                    self.selectedMarker = .existing(destinationMarker)
                }
                // Show valid target tiles based on this marker's position.
                guard let node = lookupNode(containing: destinationMarker) else { return }
                updateTargetNodes(starting: node.name)
            }
        // User tapped a tile.
        case .tappedTile(let tile):
            guard let destinationNode = findNode(named: tile.nodeName) else { return }
            switch selectedMarker {
            case .new:
                // Create a new marker at the START node, then move it to the selected tile.
                withLoadingState {
                    guard let start = self.findNode(named: .bottomRightVertex) else { return }
                    let sourceMarker = try await self.create(at: start)
                    await self.move(sourceMarker, to: destinationNode)

                    // If a marker already exists on the selected tile, piggyback on it;
                    // otherwise, register the new marker at that location.
                    if let destinationMarker = self.trackedMarkers[destinationNode] {
                        await self.piggyBack(rider: sourceMarker, carrier: destinationMarker)
                    } else {
                        self.assign(marker: sourceMarker, to: destinationNode)
                    }
                }
            case .existing(let sourceMarker):
                // Locate the current position of the selected marker.
                guard let startingNode = self.lookupNode(containing: sourceMarker) else {
                    return
                }

                withLoadingState {
                    // Move the selected marker to the tapped tile.
                    await self.move(sourceMarker, to: destinationNode)
                    
                    // If another marker already occupies the tile, piggyback onto it;
                    // otherwise, reassign the marker to the new location.
                    if let destinationMarker = self.trackedMarkers[destinationNode] {
                        await self.piggyBack(rider: sourceMarker, carrier: destinationMarker)
                        self.detachMarker(from: startingNode)
                    } else {
                        self.reassign(sourceMarker, to: destinationNode)
                    }
                }
            case .none:
                break
            }
            guard let targetNode = getTargetNode(nodeName: destinationNode.name) else { return }
            discardRoll(for: targetNode)
            clearAllTargetNodes()
            selectedMarker = .none
        }
    }

    private func create(at node: Node) async throws -> Entity {
        do {
            let position = try node.index.position()
            let entity = try await Entity(named: "Marker", in: RealityKitContent.realityKitContentBundle)
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
    
    private func move(_ marker: Entity, to node: Node) async {
        func step(entity marker: Entity, to newNode: Node) async {
            do {
                try await advance(entity: marker, to: newNode, duration: Dimensions.Marker.duration)
                await drop(marker, duration: Dimensions.Marker.duration)
            } catch {
                fatalError("Failed to move selected marker to \(newNode.index)")
            }
        }

        // Determine the starting position for the marker:
        // If it's an existing marker, use its current node;
        // if it's a new marker, default to the START node (bottomRightVertex).
        let currentNode = lookupNode(containing: marker) ?? .bottomRightVertex
        guard var route = findRoute(from: currentNode, to: node, startingPoint: currentNode) else { return }
        // exclute the starting node
        route = route.filter { $0.name != currentNode.name }

        for routeNode in route {
            await step(entity: marker, to: routeNode)
        }
    }

    private func piggyBack(rider: Entity, carrier: Entity) async {
        addLevel(tapped: carrier, moving: rider)
        removeChildFromRoot(entity: rider)
        selectedMarker = .none
    }

    private func addLevel(tapped: Entity, moving: Entity) {
        guard var tappedMarkerComponent = tapped.components[MarkerComponent.self] else { return }
        guard let movingMarkerComponent = moving.components[MarkerComponent.self] else { return }
        tappedMarkerComponent.level += movingMarkerComponent.level
        tapped.components[MarkerComponent.self] = tappedMarkerComponent
        attachmentsProvider.attachments[tapped.id] = AnyView(MarkerLevelView(tapAction: { [weak self] in
            guard let self = self else { return }
            if self.hasRemainingRoll {
                self.perform(action: .tappedMarker(tapped))
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
    
    func drop(_ marker: Entity, duration: CGFloat = 0.6) async {
        do {
            var translation = marker.position
            translation.z = Dimensions.Marker.dropped
            marker.move(to: .init(translation: translation),
                                 relativeTo: self.rootEntity,
                                 duration: duration)
            try? await Task.sleep(for: .seconds(duration))
        }
        selectedMarker = .none
        clearAllTargetNodes()
    }
}

// MARK: - RollViewModel
extension AppModel {
    var hasRemainingRoll: Bool {
        rollViewModel.hasRemainingRoll
    }

    var yootRollSteps: [String] {
        rollResult.map { "\($0.steps)" }
    }

    func discardRoll(for targetNode: TargetNode) {
        rollViewModel.discardRoll(for: targetNode)
    }
}

// MARK: - Marker Handling
private extension AppModel {
    func assign(marker: Entity, to node: Node) {
        trackedMarkers[node] = marker
    }

    func reassign(_ marker: Entity, to node: Node) {
        guard let previous = trackedMarkers.first(where: { $0.value == marker })?.key else { return }
        trackedMarkers[previous] = nil
        trackedMarkers[node] = marker
    }

    func detachMarker(from node: Node) {
        trackedMarkers[node] = nil
    }

    func lookupNode(containing marker: Entity) -> Node? {
        return trackedMarkers.first(where: {
            $0.value == marker
        })?.key
    }
}

extension AppModel {
    func findNode(named nodeName: NodeName) -> Node? {
        nodes.filter { $0.name == nodeName }.first
    }

    func nextNodeNames(from nodeName: NodeName) -> [NodeName] {
        nodes.filter { $0.name == nodeName }.first?.next ?? []
    }

    func previousNodeNames(from nodeName: NodeName) -> [NodeName] {
        nodes.filter { $0.name == nodeName }.first?.prev ?? []
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
