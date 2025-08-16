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
    enum MarkerActionError: Error {
        case markerComponentMissing(entity: Entity)
        case nodeMissing(entity: Entity)
        case targetNodeMissing(node: Node)
        case markerMoveFailed(String)
        case startNodeNotFound
        case playerNotFound(entity: Entity)
        case routeDoesNotExist(from: Node, to: Node)
    }

    private(set) var rootEntity = Entity()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - GameStateManager
    @Published private(set) var gameState: GameState = .idle
    @Published var currentTurn: Player = .none
    @Published var selectedMarker: SelectedMarker = .none
    @Published var targetNodes = Set<TargetNode>()

    var attachmentsProvider: AttachmentsProvider {
        markerManager.attachmentsProvider
    }

    var yootThrowBoard: Entity? {
        set {
            rollViewModel.yootThrowBoard = newValue
        }
        get {
            rollViewModel.yootThrowBoard
        }
    }

    // Dependencies
    private let rollViewModel: any RollViewModel
    private let gameStateManager: GameStateManager
    private let markerManager: MarkerManager
    private let gameEngine: GameEngine

    init(rollViewModel: any RollViewModel, gameStateManager: GameStateManager, markerManager: MarkerManager, gameEngine: GameEngine) {
        self.rollViewModel = rollViewModel
        self.gameStateManager = gameStateManager
        self.markerManager = markerManager
        self.gameEngine = gameEngine
        self.markerManager.rootEntity = rootEntity
        self.markerManager.delegate = self

        subscribe()
    }

    private func subscribe() {
        gameStateManager.$state
            .receive(on: RunLoop.main)
            .assign(to: \.gameState, on: self)
            .store(in: &cancellables)

        gameStateManager.$currentPlayer
                .receive(on: RunLoop.main)
                .assign(to: \.currentTurn, on: self)
                .store(in: &cancellables)

        markerManager.$selectedMarker
            .receive(on: RunLoop.main)
            .assign(to: \.selectedMarker, on: self)
            .store(in: &cancellables)
    }
}

// MARK: Button tap
extension AppModel {
    func startGame() {
        print("Starting a new game...")
        gameStateManager.startGame()
    }

    func roll() async {
        guard gameStateManager.state == .waitingForRoll ||
                gameStateManager.state == .waitingForRollOrSelect else { return }
        await rollViewModel.roll()
    }

    func debugRoll(result: Yoot) {
        gameStateManager.startRolling()

        gameStateManager.unsetCanThrowAgain()
        if result.canThrowAgain {
            gameStateManager.setCanThrowAgain()
        }

        gameStateManager.finishRolling()

        rollViewModel.result.append(result)
    }

    func handleNewMarkerTap() {
        switch gameStateManager.state {
        case .waitingForSelect, .waitingForRollOrSelect:
            gameStateManager.selectMarker()
        case .waitingForMove:
            if gameStateManager.playerCanThrowAgain {
                gameStateManager.canRollOrMove()
                break
            }
            if selectedMarker == .new {
                gameStateManager.unselectMarker()
            }
        default:
            break
        }
        clearAllTargetNodes()

        switch selectedMarker {
        case .existing, .none:
            // If a marker was already picked up, drop that marker.
            if case .existing(let entity) = selectedMarker {
                Task { @MainActor in
                    await self.markerManager.drop(entity)
                }
            }
            markerManager.setSelectedMarker(.new)
            updateTargetNodes()
        case .new:
            markerManager.setSelectedMarker(.none)
        }
    }
}

// MARK: Calculations
extension AppModel {
    func getTargetNode(nodeName: NodeName) -> TargetNode? {
        targetNodes.filter({ $0.name == nodeName }).first
    }
    
    func clearAllTargetNodes() {
        self.targetNodes.removeAll()
    }
}

// Entity action
extension AppModel {
    func perform(action: Action) throws {
        guard !rollViewModel.result.isEmpty else {
            return
        }

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
                    self.markerManager.setSelectedMarker(.none)
                    self.clearAllTargetNodes()
                    await self.markerManager.drop(destinationMarker)
                    self.updateGameState(actionResult: .drop)
                }
            } else {
                guard isTappedMarkerOnTargetNode(destinationMarker) else { return }
                guard let destinationMarkerComponent = destinationMarker.components[MarkerComponent.self] else {
                    throw MarkerManager.MarkerError.markerComponentMissing(entity: destinationMarker)
                }
                guard let sourceNode = markerManager.findNode(for: sourceMarker) else {
                    throw MarkerManager.MarkerError.nodeMissing(entity: sourceMarker)
                }
                guard let destinationNode = markerManager.findNode(for: destinationMarker) else {
                    throw MarkerManager.MarkerError.nodeMissing(entity: destinationMarker)
                }
                try discardRoll(for: destinationNode)

                gameStateManager.startAnimating()

                // If same team, piggy back.
                if currentTurn.team.rawValue == destinationMarkerComponent.team {
                    withLoadingState {
                        // Move to the destination marker’s tile.
                        try await self.markerManager.move(sourceMarker, to: destinationNode, using: self.gameEngine)

                        // Ride on top of the tapped marker.
                        try await self.markerManager.piggyBack(rider: sourceMarker, carrier: destinationMarker)
                        self.markerManager.detachMarker(from: sourceNode, player: self.currentTurn)
                        self.updateGameState(actionResult: .piggyback)
                    }
                } else {
                    // If not on the same team, capture.
                    withLoadingState {
                        // Move to the destination marker’s tile.
                        try await self.markerManager.move(sourceMarker, to: destinationNode, using: self.gameEngine)

                        // Ride on top of the tapped marker.
                        await self.handleCaptureTransition(capturingMarker: sourceMarker, capturedMarker: destinationMarker, on: destinationNode)
                        self.updateGameState(actionResult: .capture)
                    }
                }
            }
        case .new:
            let markersRemaning = availableMarkerCount(for: currentTurn)
            guard markersRemaning > 0 else { return }
            guard isTappedMarkerOnTargetNode(destinationMarker) else { return }
            guard let destinationMarkerComponent = destinationMarker.components[MarkerComponent.self] else {
                throw MarkerManager.MarkerError.markerComponentMissing(entity: destinationMarker)
            }
            guard let destinationNode = markerManager.findNode(for: destinationMarker) else {
                throw MarkerManager.MarkerError.nodeMissing(entity: destinationMarker)
            }

            try discardRoll(for: destinationNode)
            gameStateManager.startAnimating()

            // If on the same team, piggyback
            if currentTurn.team.rawValue == destinationMarkerComponent.team {
                // Attempting to place a new marker, but tapped a marker that’s already on the board.
                withLoadingState {
                    // Create a temporary marker at the START node and move it to the tapped tile.
                    // This is just for animation purposes.
                    guard let startNode = self.findNode(named: .bottomRightVertex) else {
                        throw MarkerActionError.startNodeNotFound
                    }
                    let sourceMarker = try await self.markerManager.create(at: startNode, for: self.currentTurn)
                    try await self.markerManager.move(sourceMarker, to: destinationNode, using: self.gameEngine)

                    // Piggyback onto the existing marker.
                    try await self.markerManager.piggyBack(rider: sourceMarker, carrier: destinationMarker)
                    self.updateGameState(actionResult: .piggyback)
                }
            } else {
                // If not on the same team, capture
                withLoadingState {
                    // Create a temporary marker at the START node and move it to the tapped tile.
                    // This is just for animation purposes.
                    guard let startNode = self.findNode(named: .bottomRightVertex) else {
                        throw MarkerActionError.startNodeNotFound
                    }
                    let sourceMarker = try await self.markerManager.create(at: startNode, for: self.currentTurn)
                    try await self.markerManager.move(sourceMarker, to: destinationNode, using: self.gameEngine)

                    // Piggyback onto the existing marker.
                    await self.handleCaptureTransition(capturingMarker: sourceMarker, capturedMarker: destinationMarker, on: destinationNode, isNewMarker: true)
                    self.updateGameState(actionResult: .capture)
                }
            }
        case .none:
            guard let markerComponent = destinationMarker.components[MarkerComponent.self] else {
                throw MarkerActionError.markerComponentMissing(entity: destinationMarker)
            }
            // Only allow selecting markers that belong to the current player's team; ignore taps on opponent markers
            if currentTurn.team == Team(rawValue: markerComponent.team) {
                // No marker was selected — now selecting the tapped existing marker on the board.
                gameStateManager.selectMarker()
                withLoadingState {
                    await self.markerManager.elevate(entity: destinationMarker)
                    self.markerManager.setSelectedMarker(.existing(destinationMarker))

                    // Show valid target tiles based on this marker's position.
                    guard let node = self.markerManager.findNode(for: destinationMarker) else {
                        throw MarkerActionError.nodeMissing(entity: destinationMarker)
                    }
                    self.updateTargetNodes(starting: node.name)
                    self.updateGameState(actionResult: .lift)
                }
            }
        }
    }

    func handleTileTap(_ tile: Tile) throws {
        guard let destinationNode = findNode(named: tile.nodeName) else { return }
        switch selectedMarker {
        case .new:
            let markersRemaining = availableMarkerCount(for: currentTurn)
            guard markersRemaining > 0 else { return }
            // Create a new marker at the START node, then move it to the selected tile.
            withLoadingState {
                guard let startingPosition = self.findNode(named: .bottomRightVertex) else {
                    throw MarkerActionError.startNodeNotFound
                }
                self.gameStateManager.startAnimating()
                let sourceMarker = try await self.markerManager.create(at: startingPosition, for: self.currentTurn)
                try await self.markerManager.move(sourceMarker, to: destinationNode, using: self.gameEngine)

                if let destinationMarker = self.markerManager.findMarker(for: destinationNode) {
                    // If a marker already exists on the selected tile, find which player
                    // the marker belongs to.
                    guard let player = self.markerManager.player(for: destinationMarker) else {
                        throw MarkerActionError.playerNotFound(entity: destinationMarker)
                    }
                    if player.team == self.currentTurn.team {
                        try await self.markerManager.piggyBack(rider: sourceMarker, carrier: destinationMarker)
                        self.updateGameState(actionResult: .piggyback)
                    } else {
                        await self.handleCaptureTransition(capturingMarker: sourceMarker, capturedMarker: destinationMarker, on: destinationNode, isNewMarker: true)
                        self.updateGameState(actionResult: .capture)
                    }
                } else {
                    // If no marker is on the tile, just move.
                    self.markerManager.assign(marker: sourceMarker, to: destinationNode, player: self.currentTurn)
                    self.updateGameState(actionResult: .move)
                }
            }
        case .existing(let sourceMarker):
            // Locate the current position of the selected marker.
            guard let startingNode = self.markerManager.findNode(for: sourceMarker) else {
                throw MarkerActionError.nodeMissing(entity: sourceMarker)
            }

            gameStateManager.startAnimating()

            withLoadingState {
                // Move the selected marker to the tapped tile.
                let scored = try await self.markerManager.move(sourceMarker, to: destinationNode, using: self.gameEngine)
                if scored {
                    try self.markerManager.handleScore(marker: sourceMarker, player: self.currentTurn)
                    self.updateGameState(actionResult: .score)
                } else {
                    // If another marker already occupies the tile, piggyback onto it;
                    // otherwise, reassign the marker to the new location.
                    if let destinationMarker = self.markerManager.findMarker(for: destinationNode) {
                        // If a marker already exists on the selected tile, find which player
                        // the marker belongs to.
                        guard let player = self.markerManager.player(for: destinationMarker) else {
                            throw MarkerActionError.playerNotFound(entity: destinationMarker)
                        }
                        if player.team == self.currentTurn.team {
                            try await self.markerManager.piggyBack(rider: sourceMarker, carrier: destinationMarker)
                            self.markerManager.detachMarker(from: startingNode, player: self.currentTurn)
                            self.updateGameState(actionResult: .piggyback)
                        } else {
                            await self.handleCaptureTransition(capturingMarker: sourceMarker, capturedMarker: destinationMarker, on: destinationNode)
                            self.updateGameState(actionResult: .capture)
                        }
                    } else {
                        self.markerManager.reassign(sourceMarker, to: destinationNode, player: self.currentTurn)
                        self.updateGameState(actionResult: .move)
                    }
                }
            }
        case .none:
            break
        }
        try discardRoll(for: destinationNode)
        markerManager.setSelectedMarker(.none)

    }

    private func handleCaptureTransition(
        capturingMarker: Entity,
        capturedMarker: Entity,
        on node: Node,
        isNewMarker: Bool = false
    ) async {
        await markerManager.capture(capturing: capturingMarker, captured: capturedMarker)

        // If placing a newly created marker, assign it to the destination node.
        // Otherwise, move (reassign) the existing capturing marker from its previous node.
        if isNewMarker {
            markerManager.assign(marker: capturingMarker, to: node, player: currentTurn)
        } else {
            markerManager.reassign(capturingMarker, to: node, player: currentTurn)
        }
        markerManager.setSelectedMarker(.none)
    }

    private func isGameOver() -> Bool {
        guard currentTurn.score > 0 else {
            return true
        }
        return false
    }
}

// MARK: - DebugRollViewModel
extension AppModel {
    var yootRollSteps: [String] {
        rollViewModel.result.map { "\($0.steps)" }
    }

    func discardRoll(for destinationNode: Node) throws {
        guard let targetNode = self.getTargetNode(nodeName: destinationNode.name) else {
            throw MarkerActionError.targetNodeMissing(node: destinationNode)
        }
        rollViewModel.discardRoll(for: targetNode)
        clearAllTargetNodes()
        markerManager.setSelectedMarker(.none)
    }
}

// MARK: - GameEngine integrations
private extension AppModel {
    func updateTargetNodes(starting: NodeName = .bottomRightVertex) {
        let calculatedTargetNodes = gameEngine.calculateTargetNodes(
            starting: starting,
            rollResult: rollViewModel.result
        )
        self.targetNodes = calculatedTargetNodes
    }

    func findRoute(from start: Node, to destination: Node, startingPoint: Node, visited: Set<Node> = []) -> [Node]? {
        gameEngine.findRoute(from: start, to: destination, startingPoint: startingPoint, visited: visited)
    }

    func findNode(named nodeName: NodeName) -> Node? {
        gameEngine.findNode(named: nodeName)
    }

    func nextNodeNames(from nodeName: NodeName) -> [NodeName] {
        gameEngine.nextNodeNames(from: nodeName)
    }

    func previousNodeNames(from nodeName: NodeName) -> [NodeName] {
        gameEngine.previousNodeNames(from: nodeName)
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
            do {
                try await operation()
            } catch {
                print("error occured in withLoadingState")
            }
            if isGameOver() {
                print("GAME OVER")
                gameStateManager.endGame(winner: currentTurn)
                return
            }
        }
    }
}

// MARK: - GameStateManager
extension AppModel {
    enum ActionResult {
        case piggyback
        case capture
        case move
        case score
        case drop
        case lift
    }

    func updateGameState(actionResult: ActionResult) {
        switch actionResult {
        case .move, .score, .piggyback:
            if gameStateManager.playerCanThrowAgain {
                if self.rollViewModel.result.isEmpty {
                    gameStateManager.canRollAgain()
                } else {
                    gameStateManager.canRollOrMove()
                }
            } else {
                if self.rollViewModel.result.isEmpty {
                    gameStateManager.finishTurn()
                    gameStateManager.switchTurn()
                } else {
                    gameStateManager.canMoveAgain()
                }
            }
        case .capture:
            if self.rollViewModel.result.isEmpty {
                gameStateManager.canRollAgain()
            } else {
                gameStateManager.canRollOrMove()
            }
        case .lift:
            gameStateManager.selectMarker()
        case .drop:
            if gameStateManager.playerCanThrowAgain {
                gameStateManager.canRollOrMove()
            } else {
                gameStateManager.unselectMarker()
            }
        }
    }
}

extension AppModel {
    func checkForLanding() {
        rollViewModel.checkForLanding()
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
        case .routeDoesNotExist(let from, let node):
            fatalError("Route does not exist from: \(from), to: \(node)")
        }
    }
}

extension AppModel {
    func availableMarkerCount(for player: Player) -> Int {
        return player.score - markerManager.markerCount(for: player)
    }

    // User can only tap markers that are placed on one of the target nodes.
    func isTappedMarkerOnTargetNode(_ marker: Entity) -> Bool {
        guard let node = self.markerManager.findNode(for: marker) else { return false }
        return targetNodes.contains { $0.name == node.name }
    }
}

extension AppModel: MarkerManagerProtocol {
    func didTapPromotedMarkerLevel(marker: Entity) {
        if !self.rollViewModel.result.isEmpty {
            do {
                try self.perform(action: .tappedMarker(marker))
            } catch let error as AppModel.MarkerActionError {
                error.crashApp()
            } catch {
                fatalError("Unexpected error: \(error.localizedDescription)")
            }
        }
    }
}


