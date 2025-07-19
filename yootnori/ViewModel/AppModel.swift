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
    private var rollViewModel: RollViewModel
    private var playerTurnViewModel: PlayerTurnViewModel
    private var cancellables = Set<AnyCancellable>()
    private var nodes = Set<Node>()
    private var trackedMarkers: [Player: [Node: Entity]] = [:] {
        didSet {
            print("//////////////////////")
            let _ = trackedMarkers.map { (key, value) in
                value.map { (valueKey, valueValue) in
                    print("\(key.team.name): \(valueKey.name): \(valueValue.name)")
                }
            }
        }
    }

    var shouldStartCheckingForLanding: Bool {
        rollViewModel.shouldStartCheckingForLanding
    }

    var yootThrowBoard: Entity? {
        set {
            rollViewModel.yootThrowBoard = newValue
        }
        get {
            rollViewModel.yootThrowBoard
        }
    }

    var hasMarkersLeftToPlace: Bool {
        markersLeftToPlace(for: currentTurn) > 0
    }

    @State var markersToGo: Int = 4
    @Published var selectedMarker: SelectedMarker = .none
    @Published var targetNodes = Set<TargetNode>()
    @Published var attachmentsProvider = AttachmentsProvider()
    @Published var isLoading: Bool = false
    @Published private(set) var rollResult: [Yoot] = []
    @Published var isAnimating: Bool = false
    @Published var isOutOfThrows: Bool = false
    @Published var canPlayerThrow: Bool = false
    @Published var currentTurn: Player = .none {
        didSet {
            canPlayerThrow = true
        }
    }

    init(rollViewModel: RollViewModel, playerTurnViewModel: PlayerTurnViewModel) {
        self.rollViewModel = rollViewModel
        self.playerTurnViewModel = playerTurnViewModel
        
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
        rollViewModel.resultPublisher
            .receive(on: RunLoop.main)
            .assign(to: \.rollResult, on: self)
            .store(in: &cancellables)

        rollViewModel.isAnimatingPublisher
            .receive(on: RunLoop.main)
            .assign(to: \.isAnimating, on: self)
            .store(in: &cancellables)
        
        rollViewModel.isOutOfThrowsPublisher
            .receive(on: RunLoop.main)
            .assign(to: \.isOutOfThrows, on: self)
            .store(in: &cancellables)

        rollViewModel.canPlayerThrowPublisher
            .receive(on: RunLoop.main)
            .assign(to: \.canPlayerThrow, on: self)
            .store(in: &cancellables)

        playerTurnViewModel.currentTurnPublisher
            .receive(on: RunLoop.main)
            .assign(to: \.currentTurn, on: self)
            .store(in: &cancellables)
    }
}

// MARK: Button tap
extension AppModel {
    func startGame() {
        print("Starting a new game...")
        playerTurnViewModel.updateTurn(.playerA)
    }

    func roll() {
        rollViewModel.roll()
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
    func perform(action: Action) throws {
        switch action {
        // User tapped a marker on the board.
        case .tappedMarker(let destinationMarker):
            try handleMarkerTap(destinationMarker)
        // User tapped a tile.
        case .tappedTile(let tile):
            try handleTileTap(tile)
        }
    }

    func handleMarkerTap(_ destinationMarker: Entity) throws {
        switch selectedMarker {
        case .existing(let sourceMarker):
            // Tapped the same marker again — just drop it to unselect.
            if destinationMarker == sourceMarker {
                withLoadingState {
                    await self.drop(destinationMarker)
                }
            } else {
                guard isTappedMarkerOnTargetNode(destinationMarker) else { return }
                guard let destinationMarkerComponent = destinationMarker.components[MarkerComponent.self] else {
                    throw MarkerActionError.markerComponentMissing(entity: destinationMarker)
                }
                guard let sourceNode = findNode(for: sourceMarker) else {
                    throw MarkerActionError.nodeMissing(entity: sourceMarker)
                }
                guard let destinationNode = findNode(for: destinationMarker) else {
                    throw MarkerActionError.nodeMissing(entity: destinationMarker)
                }
                try discardRoll(for: destinationNode)

                // If same team, piggy back.
                if currentTurn.team.rawValue == destinationMarkerComponent.team {
                    withLoadingState {
                        // Move to the destination marker’s tile.
                        try await self.move(sourceMarker, to: destinationNode)

                        // Ride on top of the tapped marker.
                        try await self.piggyBack(rider: sourceMarker, carrier: destinationMarker)
                        self.detachMarker(from: sourceNode)
                    }
                } else {
                    // If not on the same team, capture.
                    withLoadingState {
                        // Move to the destination marker’s tile.
                        try await self.move(sourceMarker, to: destinationNode)

                        // Ride on top of the tapped marker.
                        await self.handleCaptureTransition(capturingMarker: sourceMarker, capturedMarker: destinationMarker, on: destinationNode)
                    }
                }
            }
        case .new:
            guard hasMarkersLeftToPlace else { return }
            guard isTappedMarkerOnTargetNode(destinationMarker) else { return }
            guard let destinationMarkerComponent = destinationMarker.components[MarkerComponent.self] else {
                throw MarkerActionError.markerComponentMissing(entity: destinationMarker)
            }
            guard let destinationNode = findNode(for: destinationMarker) else {
                throw MarkerActionError.nodeMissing(entity: destinationMarker)
            }
            try discardRoll(for: destinationNode)

            // If on the same team, piggyback
            if currentTurn.team.rawValue == destinationMarkerComponent.team {
                // Attempting to place a new marker, but tapped a marker that’s already on the board.
                withLoadingState {
                    // Create a temporary marker at the START node and move it to the tapped tile.
                    // This is just for animation purposes.
                    guard let startNode = self.findNode(named: .bottomRightVertex) else {
                        throw MarkerActionError.startNodeNotFound
                    }
                    let sourceMarker = try await self.create(at: startNode)
                    try await self.move(sourceMarker, to: destinationNode)

                    // Piggyback onto the existing marker.
                    try await self.piggyBack(rider: sourceMarker, carrier: destinationMarker)
                }
            } else {
                // If not on the same team, capture
                withLoadingState {
                    // Create a temporary marker at the START node and move it to the tapped tile.
                    // This is just for animation purposes.
                    guard let startNode = self.findNode(named: .bottomRightVertex) else {
                        throw MarkerActionError.startNodeNotFound
                    }
                    let sourceMarker = try await self.create(at: startNode)
                    try await self.move(sourceMarker, to: destinationNode)

                    // Piggyback onto the existing marker.
                    await self.handleCaptureTransition(capturingMarker: sourceMarker, capturedMarker: destinationMarker, on: destinationNode, isNewMarker: true)
                }
            }
        case .none:
            guard let markerComponent = destinationMarker.components[MarkerComponent.self] else {
                throw MarkerActionError.markerComponentMissing(entity: destinationMarker)
            }
            // Only allow selecting markers that belong to the current player's team; ignore taps on opponent markers
            if currentTurn.team == Team(rawValue: markerComponent.team) {
                // No marker was selected — now selecting the tapped existing marker on the board.
                withLoadingState {
                    await self.elevate(entity: destinationMarker)
                    self.selectedMarker = .existing(destinationMarker)
                }
                // Show valid target tiles based on this marker's position.
                guard let node = findNode(for: destinationMarker) else {
                    throw MarkerActionError.nodeMissing(entity: destinationMarker)
                }
                updateTargetNodes(starting: node.name)
            }
        }
    }

    func handleTileTap(_ tile: Tile) throws {
        guard let destinationNode = findNode(named: tile.nodeName) else { return }
        switch selectedMarker {
        case .new:
            guard hasMarkersLeftToPlace else { return }
            // Create a new marker at the START node, then move it to the selected tile.
            withLoadingState {
                guard let startingPosition = self.findNode(named: .bottomRightVertex) else {
                    throw MarkerActionError.startNodeNotFound
                }
                let sourceMarker = try await self.create(at: startingPosition)
                try await self.move(sourceMarker, to: destinationNode)

                if let destinationMarker = self.findMarker(for: destinationNode) {
                    // If a marker already exists on the selected tile, find which player
                    // the marker belongs to.
                    guard let player = self.player(for: destinationMarker) else {
                        throw MarkerActionError.playerNotFound(entity: destinationMarker)
                    }
                    if player.team == self.currentTurn.team {
                        try await self.piggyBack(rider: sourceMarker, carrier: destinationMarker)
                    } else {
                        await self.handleCaptureTransition(capturingMarker: sourceMarker, capturedMarker: destinationMarker, on: destinationNode, isNewMarker: true)
                    }
                } else {
                    // If no marker is on the tile, just move.
                    self.assign(marker: sourceMarker, to: destinationNode)
                }
            }
        case .existing(let sourceMarker):
            // Locate the current position of the selected marker.
            guard let startingNode = self.findNode(for: sourceMarker) else {
                throw MarkerActionError.nodeMissing(entity: sourceMarker)
            }

            withLoadingState {
                // Move the selected marker to the tapped tile.
                try await self.move(sourceMarker, to: destinationNode)

                // If another marker already occupies the tile, piggyback onto it;
                // otherwise, reassign the marker to the new location.
                if let destinationMarker = self.findMarker(for: destinationNode) {
                    // If a marker already exists on the selected tile, find which player
                    // the marker belongs to.
                    guard let player = self.player(for: destinationMarker) else {
                        throw MarkerActionError.playerNotFound(entity: destinationMarker)
                    }
                    if player.team == self.currentTurn.team {
                        try await self.piggyBack(rider: sourceMarker, carrier: destinationMarker)
                        self.detachMarker(from: startingNode)
                    } else {
                        await self.handleCaptureTransition(capturingMarker: sourceMarker, capturedMarker: destinationMarker, on: destinationNode)
                    }
                } else {
                    self.reassign(sourceMarker, to: destinationNode)
                }
            }
        case .none:
            break
        }
        try discardRoll(for: destinationNode)
        selectedMarker = .none
    }

    private func create(at node: Node) async throws -> Entity {
        do {
            let position = try node.index.position()
            let entity = try await Entity(named: currentTurn.markerName, in: RealityKitContent.realityKitContentBundle)
            entity.position = position
            entity.components.set([
                CollisionComponent(shapes: [{
                    .generateBox(size: entity.visualBounds(relativeTo: nil).extents)
                }()]),
                InputTargetComponent(),
                MarkerComponent(level: 1, team: currentTurn.team.rawValue)
            ])
            addChildToRoot(entity: entity)
            return entity
        } catch {
            fatalError("Failed to create a new marker at \(node.index)")
        }
    }
    
    private func move(_ marker: Entity, to node: Node) async throws {
        func step(entity marker: Entity, to newNode: Node) async throws {
            do {
                try await advance(entity: marker, to: newNode, duration: Dimensions.Marker.duration)
                await drop(marker, duration: Dimensions.Marker.duration)
            } catch {
                throw MarkerActionError.markerMoveFailed("Failed to move selected marker to \(newNode.index)")
            }
        }

        // Determine the starting position for the marker:
        // If it's an existing marker, use its current node;
        // if it's a new marker, default to the START node (bottomRightVertex).
        let currentNode = findNode(for: marker) ?? .bottomRightVertex
        guard var route = findRoute(from: currentNode, to: node, startingPoint: currentNode) else { return }
        // exclute the starting node
        route = route.filter { $0.name != currentNode.name }

        for routeNode in route {
            try await step(entity: marker, to: routeNode)
        }
    }

    private func piggyBack(rider: Entity, carrier: Entity) async throws {
        try addLevel(tapped: carrier, moving: rider)
        removeChildFromRoot(entity: rider)
        selectedMarker = .none
    }

    private func handleCaptureTransition(
        capturingMarker: Entity,
        capturedMarker: Entity,
        on node: Node,
        isNewMarker: Bool = false
    ) async {
        await self.capture(capturing: capturingMarker, captured: capturedMarker)
        self.detachMarker(from: node, player: self.currentTurn.opponent)
        // If placing a newly created marker, assign it to the destination node.
        // Otherwise, move (reassign) the existing capturing marker from its previous node.
        if isNewMarker {
            self.assign(marker: capturingMarker, to: node)
        } else {
            self.reassign(capturingMarker, to: node)
        }
        self.canPlayerThrow = true
    }

    private func capture(capturing: Entity, captured: Entity) async {
        removeChildFromRoot(entity: captured)
        selectedMarker = .none
    }

    private func addLevel(tapped: Entity, moving: Entity) throws {
        guard var tappedMarkerComponent = tapped.components[MarkerComponent.self] else {
            throw MarkerActionError.markerComponentMissing(entity: tapped)
        }
        guard let movingMarkerComponent = moving.components[MarkerComponent.self] else {
            throw MarkerActionError.markerComponentMissing(entity: moving)
        }
        tappedMarkerComponent.level += movingMarkerComponent.level
        tapped.components[MarkerComponent.self] = tappedMarkerComponent
        attachmentsProvider.attachments[tapped.id] = AnyView(MarkerLevelView(tapAction: { [weak self] in
            guard let self = self else { return }
            if !self.isOutOfThrows {
                do {
                    try self.perform(action: .tappedMarker(tapped))
                } catch let error as AppModel.MarkerActionError {
                    error.crashApp()
                } catch {
                    fatalError("Unexpected error: \(error.localizedDescription)")
                }
            }
        }, level: tappedMarkerComponent.level, team: Team(rawValue: tappedMarkerComponent.team) ?? .black))
    }
}

// MARK: Marker animation

private extension AppModel {
    func advance(entity marker: Entity, to node: Node, duration: CGFloat) async throws {
        let newPosition = try node.index.position()
        var translation = newPosition
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
        selectedMarker = .none
        clearAllTargetNodes()
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

// MARK: - DebugRollViewModel
extension AppModel {
    var yootRollSteps: [String] {
        rollResult.map { "\($0.steps)" }
    }

    func discardRoll(for destinationNode: Node) throws {
        guard let targetNode = self.getTargetNode(nodeName: destinationNode.name) else {
            throw MarkerActionError.targetNodeMissing(node: destinationNode)
        }
        rollViewModel.discardRoll(for: targetNode)
        clearAllTargetNodes()
    }
}

// MARK: - Marker Handling
private extension AppModel {
    func assign(marker: Entity, to node: Node, player: Player? = nil) {
        let owner = player ?? currentTurn
        trackedMarkers[owner, default: [:]][node] = marker
    }

    func reassign(_ marker: Entity, to node: Node, player: Player? = nil) {
        let owner = player ?? currentTurn
        guard let previous = trackedMarkers[owner]?.first(where: { $0.value == marker })?.key else { return }
        trackedMarkers[owner]?[previous] = nil
        trackedMarkers[owner]?[node] = marker
    }

    func detachMarker(from node: Node, player: Player? = nil) {
        let owner = player ?? currentTurn
        trackedMarkers[owner]?[node] = nil
    }

    func findNode(for marker: Entity, player: Player? = nil) -> Node? {
        let owner = player ?? currentTurn
        return trackedMarkers[owner]?.first(where: { $0.value == marker })?.key
    }

    /// For lookup across *all* players (if player is not known)
    func findNode(for marker: Entity) -> Node? {
        for (_, dict) in trackedMarkers {
            if let node = dict.first(where: { $0.value == marker })?.key {
                return node
            }
        }
        return nil
    }

    /// For lookup across *all* players (if player is not known)
    func findMarker(for node: Node) -> Entity? {
        for (_, dict) in trackedMarkers {
            if let marker = dict.first(where: { $0.key == node })?.value {
                return marker
            }
        }
        return nil
    }

    func player(for marker: Entity) -> Player? {
        for (player, markers) in trackedMarkers {
            if markers.values.contains(marker) {
                return player
            }
        }
        return nil
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

            if self.isOutOfThrows && !canPlayerThrow {
                self.playerTurnViewModel.switchTurn()
            }
        }
    }
}

extension AppModel {
    func checkForLanding() {
        rollViewModel.checkForLanding()
    }
}

// MARK: - trackedMarkers
extension AppModel {
    subscript(player: Player) -> [Node: Entity] {
        get { trackedMarkers[player, default: [:]] }
        set { trackedMarkers[player] = newValue }
    }
}

extension AppModel {
    enum MarkerActionError: Error {
        case markerComponentMissing(entity: Entity)
        case nodeMissing(entity: Entity)
        case targetNodeMissing(node: Node)
        case markerMoveFailed(String)
        case startNodeNotFound
        case playerNotFound(entity: Entity)
    }
}

extension AppModel.MarkerActionError {
    func crashApp() -> Never {
        switch self {
        case .markerComponentMissing(let entity):
            fatalError("Marker component is missing for entity: \(entity)")
        case .nodeMissing(let entity):
            fatalError("Node is missing for entity: \(entity)")
        case .targetNodeMissing(let node):
            fatalError("Target node is missing for node: \(node)")
        case .markerMoveFailed(let reason):
            fatalError("Failed to move marker: \(reason)")
        case .startNodeNotFound:
            fatalError("Start node could not be found.")
        case .playerNotFound(let entity):
            fatalError("Player not found for entity: \(entity)")
        }
    }
}

extension AppModel {
    private func markerCount(for player: Player) -> Int {
        trackedMarkers[player]?.values.reduce(into: 0) { count, marker in
            guard let level = marker.components[MarkerComponent.self]?.level else {
                fatalError()
            }
            return count += level
        } ?? 0
    }

    func markersLeftToPlace(for player: Player) -> Int {
        player.score - markerCount(for: player)
    }

    // User can only tap markers that are placed on one of the target nodes.
    func isTappedMarkerOnTargetNode(_ marker: Entity) -> Bool {
        guard let node = findNode(for: marker) else { return false }
        return targetNodes.contains { $0.name == node.name }
    }
}
