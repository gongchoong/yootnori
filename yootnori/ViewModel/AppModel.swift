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
import GroupActivities

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
        case invalidSelectedMarker(SelectedMarker)
    }

    private(set) var rootEntity = Entity()
    private var cancellables = Set<AnyCancellable>()
    private let actionEventEmitter = ActionEventEmitter()

    var rollResult: [Yoot] {
        rollViewModel.result
    }

    var gameState: GameState {
        gameStateManager.state
    }

    var currentTurn: Player {
        gameStateManager.currentPlayer
    }

    var selectedMarker: SelectedMarker {
        markerManager.selectedMarker
    }

    var targetNodes: Set<TargetNode> {
        gameEngine.targetNodes
    }

    var attachmentsProvider: AttachmentsProvider {
        markerManager.attachmentsProvider
    }

    var markerCanScore: Bool {
        gameEngine.targetNodes.contains { $0.name == .bottomRightVertex && $0.canScore }
    }

    // Dependencies
    private let rollViewModel: any RollViewModel
    private let gameStateManager: GameStateManager
    private let markerManager: MarkerManager
    private let gameEngine: GameEngine
    private let sharePlayManager: SharePlayManagerProtocol

    init(rollViewModel: any RollViewModel, gameStateManager: GameStateManager, markerManager: MarkerManager, gameEngine: GameEngine, sharePlayManager: SharePlayManagerProtocol) {
        self.rollViewModel = rollViewModel
        self.gameStateManager = gameStateManager
        self.markerManager = markerManager
        self.gameEngine = gameEngine
        self.sharePlayManager = sharePlayManager
        self.rollViewModel.delegate = self
        self.markerManager.rootEntity = rootEntity
        self.markerManager.delegate = self

        subscribe()
        observe()
    }

    private func observe() {
        Task { @MainActor in
            for await actionEvent in actionEventEmitter.stream {
                do {
                    try await handleActionEvent(actionEvent)
                } catch {
                    fatalError("\(error)")
                }
            }
        }
    }

    private func subscribe() {
        rollViewModel.resultPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        gameStateManager.$state
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        gameStateManager.$currentPlayer
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        markerManager.$selectedMarker
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        gameEngine.$targetNodes
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

    }
}

extension AppModel {
    func emit(event: ActionEvent) {
        actionEventEmitter.emit(event)
    }

    func setYootThrowBoard(_ board: Entity) {
        rollViewModel.yootThrowBoard = board
    }
}

private extension AppModel {
    func handleActionEvent(_ actionEvent: ActionEvent) async throws {
        switch actionEvent {
        case .startGame:
            startGame()
        case .tapMarker(let marker):
            try await handleMarkerTap(marker)
        case .tapTile(let tile):
            try await handleTileTap(tile)
        case .tapNew:
            await handleNewMarkerTap()
        case .tapRoll:
            await roll()
        case .tapDebugRoll(let result):
            debugRoll(result)
        case .score:
            try await handleScore()
        }
    }
}

// MARK: Button tap
extension AppModel {
    func startGame() {
        gameStateManager.startGame()
    }

    func roll() async {
        guard gameStateManager.state == .waitingForRoll ||
                gameStateManager.state == .waitingForRollOrSelect else { return }

        await rollViewModel.roll()
    }

    func debugRoll(_ result: Yoot) {
        gameStateManager.startRolling()

        if result.canThrowAgain {
            gameStateManager.setCanThrowAgain()
        } else {
            gameStateManager.unsetCanThrowAgain()
        }

        gameStateManager.finishRolling()
        rollViewModel.result.append(result)
    }

    func handleNewMarkerTap() async {
        // Update game state.
        switch gameStateManager.state {
        case .waitingForSelect, .waitingForRollOrSelect:
            gameStateManager.selectMarker()
        case .waitingForMove:
            if gameStateManager.playerCanThrowAgain {
                gameStateManager.canRollOrMove()
            } else if selectedMarker == .new {
                gameStateManager.unselectMarker()
            }
        default:
            break
        }

        // Run animation, then update markers and target nodes.
        switch selectedMarker {
            case .existing(let entity):
                await markerManager.drop(entity)
                markerManager.setSelectedMarker(.new)
                gameEngine.updateTargetNodes(for: rollViewModel.result)

            case .none:
                markerManager.setSelectedMarker(.new)
                gameEngine.updateTargetNodes(for: rollViewModel.result)

            case .new:
                markerManager.setSelectedMarker(.none)
                gameEngine.clearAllTargetNodes()
            }
    }
}

// MARK: - Entity action
extension AppModel {
    func handleMarkerTap(_ destinationMarker: Entity) async throws {
        switch selectedMarker {
        case .existing(let sourceMarker):
                // Tapped the same marker again — just drop it to unselect.
            if destinationMarker == sourceMarker {
                markerManager.setSelectedMarker(.none)
                gameEngine.clearAllTargetNodes()

                await markerManager.drop(destinationMarker)
                updateGameState(actionResult: .drop)
            } else {
                guard try onTargetNode(destinationMarker) else { return }
                let destinationMarkerComponent = try destinationMarker.component()
                let sourceNode = try markerManager.findNode(for: sourceMarker)
                let destinationNode = try markerManager.findNode(for: destinationMarker)

                try discardRoll(for: destinationNode)
                gameEngine.clearAllTargetNodes()
                markerManager.setSelectedMarker(.none)

                gameStateManager.startAnimating()

                    // If same team, piggy back.
                if currentTurn.team.rawValue == destinationMarkerComponent.team {
                        // Move to the destination marker’s tile.
                    try await markerManager.move(sourceMarker, to: destinationNode, using: gameEngine)

                        // Ride on top of the tapped marker.
                    try await markerManager.piggyBack(rider: sourceMarker, carrier: destinationMarker)
                    markerManager.detachMarker(from: sourceNode, player: currentTurn)
                    updateGameState(actionResult: .piggyback)
                } else {
                        // If not on the same team, capture.
                        // Move to the destination marker’s tile.
                    try await markerManager.move(sourceMarker, to: destinationNode, using: gameEngine)

                    await markerManager.capture(capturing: sourceMarker, captured: destinationMarker)
                        // Move (reassign) the existing capturing marker from its previous node to the destination node.
                    markerManager.reassign(sourceMarker, to: destinationNode, player: currentTurn)
                    updateGameState(actionResult: .capture)
                }
            }
        case .new:
            let markersRemaning = availableMarkerCount(for: currentTurn)
            guard markersRemaning > 0 else { return }
            guard try onTargetNode(destinationMarker) else { return }
            let destinationMarkerComponent = try destinationMarker.component()
            let destinationNode = try markerManager.findNode(for: destinationMarker)

            try discardRoll(for: destinationNode)
            gameEngine.clearAllTargetNodes()
            markerManager.setSelectedMarker(.none)

            gameStateManager.startAnimating()

                // If on the same team, piggyback
            if currentTurn.team.rawValue == destinationMarkerComponent.team {
                    // Attempting to place a new marker, but tapped a marker that’s already on the board.
                    // Create a temporary marker at the START node and move it to the tapped tile.
                    // This is just for animation purposes.
                guard let startNode = findNode(named: .bottomRightVertex) else {
                    throw MarkerActionError.startNodeNotFound
                }
                let sourceMarker = try await markerManager.create(at: startNode, for: currentTurn)
                try await markerManager.move(sourceMarker, to: destinationNode, using: gameEngine)

                    // Piggyback onto the existing marker.
                try await markerManager.piggyBack(rider: sourceMarker, carrier: destinationMarker)
                updateGameState(actionResult: .piggyback)
            } else {
                    // If not on the same team, capture
                    // Create a temporary marker at the START node and move it to the tapped tile.
                    // This is just for animation purposes.
                guard let startNode = findNode(named: .bottomRightVertex) else {
                    throw MarkerActionError.startNodeNotFound
                }
                let sourceMarker = try await markerManager.create(at: startNode, for: self.currentTurn)
                try await markerManager.move(sourceMarker, to: destinationNode, using: self.gameEngine)

                await markerManager.capture(capturing: sourceMarker, captured: destinationMarker)
                    // Assign the new marker to the destination node.
                markerManager.assign(marker: sourceMarker, to: destinationNode, player: currentTurn)
                updateGameState(actionResult: .capture)
            }
        case .none:
            guard let markerComponent = destinationMarker.components[MarkerComponent.self] else {
                throw MarkerActionError.markerComponentMissing(entity: destinationMarker)
            }
                // Only allow selecting markers that belong to the current player's team; ignore taps on opponent markers
            if currentTurn.team == Team(rawValue: markerComponent.team) &&
                (gameStateManager.state == .waitingForRollOrSelect || gameStateManager.state == .waitingForSelect) {
                // No marker was selected — now selecting the tapped existing marker on the board.
                gameStateManager.selectMarker()
                await markerManager.elevate(entity: destinationMarker)
                markerManager.setSelectedMarker(.existing(destinationMarker))

                // Show valid target tiles based on this marker's position.
                let node = try markerManager.findNode(for: destinationMarker)
                gameEngine.updateTargetNodes(starting: node.name, for: rollViewModel.result)
                updateGameState(actionResult: .lift)
            }
        }
    }

    func handleTileTap(_ tile: Tile) async throws {
        guard let destinationNode = findNode(named: tile.nodeName) else { return }
        switch selectedMarker {
        case .new:
            let markersRemaining = availableMarkerCount(for: currentTurn)
            guard markersRemaining > 0 else { return }

            try discardRoll(for: destinationNode)
            gameEngine.clearAllTargetNodes()
            markerManager.setSelectedMarker(.none)

            self.gameStateManager.startAnimating()
            let sourceMarker = try await self.markerManager.create(at: .bottomRightVertex, for: self.currentTurn)
            try await self.markerManager.move(sourceMarker, to: destinationNode, using: self.gameEngine)


            if let destinationMarker = self.markerManager.findMarker(for: destinationNode) {
                // If a marker already exists on the selected tile, find which player
                // the marker belongs to.
                guard let player = self.markerManager.player(for: destinationMarker) else {
                    throw MarkerActionError.playerNotFound(entity: destinationMarker)
                }
                // If on the same team, piggyback.
                if player.team == self.currentTurn.team {
                    try await self.markerManager.piggyBack(rider: sourceMarker, carrier: destinationMarker)
                    self.updateGameState(actionResult: .piggyback)
                } else {
                    // If not on the same team, capture.
                    await markerManager.capture(capturing: sourceMarker, captured: destinationMarker)

                    // Assign the new marker to the destination node.
                    markerManager.assign(marker: sourceMarker, to: destinationNode, player: currentTurn)
                    self.updateGameState(actionResult: .capture)
                }
            } else {
                // If no marker is on the tile, just move.
                self.markerManager.assign(marker: sourceMarker, to: destinationNode, player: self.currentTurn)
                self.updateGameState(actionResult: .move)
            }
        case .existing(let sourceMarker):
            // Locate the current position of the selected marker.
            let startingNode = try self.markerManager.findNode(for: sourceMarker)

            try discardRoll(for: destinationNode)
            gameEngine.clearAllTargetNodes()
            markerManager.setSelectedMarker(.none)

            gameStateManager.startAnimating()

                // Move the selected marker to the tapped tile.
                try await self.markerManager.move(sourceMarker, to: destinationNode, using: self.gameEngine)

                // If another marker already occupies the tile, piggyback onto it;
                // otherwise, reassign the marker to the new location.
                if let destinationMarker = self.markerManager.findMarker(for: destinationNode) {
                    // If a marker already exists on the selected tile, find which player
                    // the marker belongs to.
                    guard let player = self.markerManager.player(for: destinationMarker) else {
                        throw MarkerActionError.playerNotFound(entity: destinationMarker)
                    }
                    // If on the same team, piggy back.
                    if player.team == self.currentTurn.team {
                        try await self.markerManager.piggyBack(rider: sourceMarker, carrier: destinationMarker)
                        self.markerManager.detachMarker(from: startingNode, player: self.currentTurn)
                        self.updateGameState(actionResult: .piggyback)
                    } else {
                        // If not on the same team, capture.
                        await markerManager.capture(capturing: sourceMarker, captured: destinationMarker)

                        // Move (reassign) the existing capturing marker from its previous node to the destination node.
                        markerManager.reassign(sourceMarker, to: destinationNode, player: currentTurn)
                        self.updateGameState(actionResult: .capture)
                    }
                } else {
                    self.markerManager.reassign(sourceMarker, to: destinationNode, player: self.currentTurn)
                    self.updateGameState(actionResult: .move)
                }
        case .none:
            break
        }
    }

    private func handleScore() async throws {
        switch selectedMarker {
        case .existing(let sourceMarker):
            try self.discardRoll(name: .bottomRightVertex)
            gameEngine.clearAllTargetNodes()

            gameStateManager.startAnimating()

            try await self.markerManager.move(sourceMarker, to: .bottomRightVertex, using: self.gameEngine)
            try self.markerManager.handleScore(player: self.currentTurn)

            markerManager.setSelectedMarker(.none)
            self.updateGameState(actionResult: .score)
        default:
            throw MarkerActionError.invalidSelectedMarker(selectedMarker)
        }
    }
}

extension AppModel {
    func availableMarkerCount(for player: Player) -> Int {
        return player.score - markerManager.markerCount(for: player)
    }

    // User can only tap markers that are placed on one of the target nodes.
    func onTargetNode(_ marker: Entity) throws -> Bool {
        let node = try markerManager.findNode(for: marker)
        return targetNodes.contains { $0.name == node.name }
    }

    func checkForLanding() {
        rollViewModel.checkForLanding()
    }
}

// MARK: - Tile
extension AppModel {
    func shouldHighlight(for tile: Tile) -> Bool {
        targetNodes.contains { $0.name == tile.nodeName && !$0.canScore }
    }
}

// MARK: - DebugRollViewModel
extension AppModel {
    var yootRollSteps: [String] {
        rollViewModel.result.map { "\($0.steps)" }
    }

    func discardRoll(for destinationNode: Node) throws {
        guard let targetNode = self.gameEngine.getTargetNode(nodeName: destinationNode.name) else {
            throw MarkerActionError.targetNodeMissing(node: destinationNode)
        }
        rollViewModel.discardRoll(for: targetNode)
    }

    func discardRoll(name: NodeName) throws {
        guard let targetNode = self.gameEngine.getTargetNode(nodeName: name) else {
            throw MarkerActionError.targetNodeMissing(node: .bottomRightVertex)
        }
        rollViewModel.discardRoll(for: targetNode)
    }
}

// MARK: - GameEngine integrations
private extension AppModel {
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

    func isGameOver() -> Bool {
        return currentTurn.score > 0 ? false : true
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
            gameStateManager.setCanThrowAgain()
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
        case .invalidSelectedMarker(let selectedMarker):
            fatalError("Selected marker not found: \(selectedMarker)")
        }
    }
}

extension AppModel: MarkerManagerProtocol {
    func didTapPromotedMarkerLevel(marker: Entity) {
        if !self.rollViewModel.result.isEmpty {
            self.emit(event: .tapMarker(marker))
        }
    }
}

@MainActor
extension AppModel: @preconcurrency RollViewModelDelegate {
    func rollViewModelDidStartRoll() {
        // gameStateManager.unsetCanThrowAgain()
        gameStateManager.startRolling()
    }

    func rollViewModelDidFinishRoll() {
        gameStateManager.finishRolling()
    }

    func rollViewModelDidDetectDouble() {
        gameStateManager.setCanThrowAgain()
    }
}

// MARK: - Group Activity
extension AppModel {
    func startSharePlay() {
        self.sharePlayManager.startSharePlay()
    }

    func configureGroupSessions() {
        self.sharePlayManager.configureGroupSessions()
    }

    func sendMessage() {
        let message = GroupMessage(id: .init(), message: "Test message \(Date.now)")
        self.sharePlayManager.sendMessage(message)
    }
}
