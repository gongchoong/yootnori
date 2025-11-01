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

    // Dependencies
    private let rollManager: YootRollManager
    private var gameStateManager: GameStateManager
    private let markerManager: MarkerManager
    private var gameEngine: GameEngine
    private let sharePlayManager: SharePlayManagerProtocol

    init(rollManager: YootRollManager, gameStateManager: GameStateManager, markerManager: MarkerManager, gameEngine: GameEngine, sharePlayManager: SharePlayManagerProtocol) {
        self.rollManager = rollManager
        self.gameStateManager = gameStateManager
        self.markerManager = markerManager
        self.gameEngine = gameEngine
        self.sharePlayManager = sharePlayManager
        self.rollManager.delegate = self
        self.markerManager.rootEntity = rootEntity
        self.markerManager.delegate = self

        observe()
        subscribe()
    }

    private(set) var rootEntity = Entity()
    private var cancellables = Set<AnyCancellable>()
    private let actionEventEmitter = ActionEventEmitter()

    @Published private(set) var gameState: GameState = .idle
    @Published private(set) var targetNodes: Set<TargetNode> = []
    @Published private(set) var currentPlayer: Player = .none
    @Published private(set) var selectedMarker: SelectedMarker = .none
    @Published private(set) var result: [Yoot] = []

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
        gameStateManager.$state
            .receive(on: RunLoop.main)
            .assign(to: &$gameState)

        gameStateManager.$currentPlayer
            .receive(on: RunLoop.main)
            .assign(to: &$currentPlayer)

        gameEngine.$targetNodes
            .receive(on: RunLoop.main)
            .assign(to: &$targetNodes)

        markerManager.$selectedMarker
            .receive(on: RunLoop.main)
            .assign(to: &$selectedMarker)

        rollManager.resultPublisher
            .receive(on: RunLoop.main)
            .assign(to: &$result)
    }
}

extension AppModel {
    func emit(event: ActionEvent) {
        actionEventEmitter.emit(event)
    }

    private func handleActionEvent(_ actionEvent: ActionEvent) async throws {
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
            try await roll()
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

    func roll() async throws {
        guard gameStateManager.state == .waitingForRoll ||
                gameStateManager.state == .waitingForRollOrSelect else { return }

        try await rollManager.roll()
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
            gameEngine.updateTargetNodes(for: result)

        case .none:
            markerManager.setSelectedMarker(.new)
            gameEngine.updateTargetNodes(for: result)

        case .new:
            markerManager.setSelectedMarker(.none)
            gameEngine.clearAllTargetNodes()
        }
    }
}

// MARK: - Entity action
private extension AppModel {
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
                if currentPlayer.team.rawValue == destinationMarkerComponent.team {
                        // Move to the destination marker’s tile.
                    try await markerManager.move(sourceMarker, to: destinationNode, using: gameEngine)

                        // Ride on top of the tapped marker.
                    try await markerManager.piggyBack(rider: sourceMarker, carrier: destinationMarker)
                    markerManager.detachMarker(from: sourceNode, player: currentPlayer)
                    updateGameState(actionResult: .piggyback)
                } else {
                        // If not on the same team, capture.
                        // Move to the destination marker’s tile.
                    try await markerManager.move(sourceMarker, to: destinationNode, using: gameEngine)

                    await markerManager.capture(capturing: sourceMarker, captured: destinationMarker)
                        // Move (reassign) the existing capturing marker from its previous node to the destination node.
                    markerManager.reassign(sourceMarker, to: destinationNode, player: currentPlayer)
                    updateGameState(actionResult: .capture)
                }
            }
        case .new:
            guard remainingMarkerCount(for: currentPlayer) > 0 else { return }
            guard try onTargetNode(destinationMarker) else { return }
            let destinationMarkerComponent = try destinationMarker.component()
            let destinationNode = try markerManager.findNode(for: destinationMarker)

            try discardRoll(for: destinationNode)
            gameEngine.clearAllTargetNodes()
            markerManager.setSelectedMarker(.none)

            gameStateManager.startAnimating()

                // If on the same team, piggyback
            if currentPlayer.team.rawValue == destinationMarkerComponent.team {
                 // Attempting to place a new marker, but tapped a marker that’s already on the board.
                 // Create a temporary marker at the START node and move it to the tapped tile.
                 // This is just for animation purposes.
                let startNode = try gameEngine.findNode(named: .bottomRightVertex)
                let sourceMarker = try await markerManager.create(at: startNode, for: currentPlayer)
                try await markerManager.move(sourceMarker, to: destinationNode, using: gameEngine)

                    // Piggyback onto the existing marker.
                try await markerManager.piggyBack(rider: sourceMarker, carrier: destinationMarker)
                updateGameState(actionResult: .piggyback)
            } else {
                // If not on the same team, capture
                // Create a temporary marker at the START node and move it to the tapped tile.
                // This is just for animation purposes.
                let startNode = try gameEngine.findNode(named: .bottomRightVertex)
                let sourceMarker = try await markerManager.create(at: startNode, for: self.currentPlayer)
                try await markerManager.move(sourceMarker, to: destinationNode, using: self.gameEngine)

                await markerManager.capture(capturing: sourceMarker, captured: destinationMarker)
                    // Assign the new marker to the destination node.
                markerManager.assign(marker: sourceMarker, to: destinationNode, player: currentPlayer)
                updateGameState(actionResult: .capture)
            }
        case .none:
            guard let markerComponent = destinationMarker.components[MarkerComponent.self] else {
                throw MarkerActionError.markerComponentMissing(entity: destinationMarker)
            }
                // Only allow selecting markers that belong to the current player's team; ignore taps on opponent markers
            if currentPlayer.team == Team(rawValue: markerComponent.team) &&
                (gameStateManager.state == .waitingForRollOrSelect || gameStateManager.state == .waitingForSelect) {
                // No marker was selected — now selecting the tapped existing marker on the board.
                gameStateManager.selectMarker()
                await markerManager.elevate(entity: destinationMarker)
                markerManager.setSelectedMarker(.existing(destinationMarker))

                // Show valid target tiles based on this marker's position.
                let node = try markerManager.findNode(for: destinationMarker)
                gameEngine.updateTargetNodes(starting: node.name, for: result)
                updateGameState(actionResult: .lift)
            }
        }
    }

    func handleTileTap(_ tile: Tile) async throws {
        let destinationNode = try gameEngine.findNode(named: tile.nodeName)
        switch selectedMarker {
        case .new:
            guard remainingMarkerCount(for: currentPlayer) > 0 else { return }

            try discardRoll(for: destinationNode)
            gameEngine.clearAllTargetNodes()
            markerManager.setSelectedMarker(.none)

            self.gameStateManager.startAnimating()
            let sourceMarker = try await self.markerManager.create(at: .bottomRightVertex, for: self.currentPlayer)
            try await self.markerManager.move(sourceMarker, to: destinationNode, using: self.gameEngine)


            if let destinationMarker = self.markerManager.findMarker(for: destinationNode) {
                // If a marker already exists on the selected tile, find which player
                // the marker belongs to.
                guard let player = self.markerManager.player(for: destinationMarker) else {
                    throw MarkerActionError.playerNotFound(entity: destinationMarker)
                }
                // If on the same team, piggyback.
                if player.team == self.currentPlayer.team {
                    try await self.markerManager.piggyBack(rider: sourceMarker, carrier: destinationMarker)
                    self.updateGameState(actionResult: .piggyback)
                } else {
                    // If not on the same team, capture.
                    await markerManager.capture(capturing: sourceMarker, captured: destinationMarker)

                    // Assign the new marker to the destination node.
                    markerManager.assign(marker: sourceMarker, to: destinationNode, player: currentPlayer)
                    self.updateGameState(actionResult: .capture)
                }
            } else {
                // If no marker is on the tile, just move.
                self.markerManager.assign(marker: sourceMarker, to: destinationNode, player: self.currentPlayer)
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
                    if player.team == self.currentPlayer.team {
                        try await self.markerManager.piggyBack(rider: sourceMarker, carrier: destinationMarker)
                        self.markerManager.detachMarker(from: startingNode, player: self.currentPlayer)
                        self.updateGameState(actionResult: .piggyback)
                    } else {
                        // If not on the same team, capture.
                        await markerManager.capture(capturing: sourceMarker, captured: destinationMarker)

                        // Move (reassign) the existing capturing marker from its previous node to the destination node.
                        markerManager.reassign(sourceMarker, to: destinationNode, player: currentPlayer)
                        self.updateGameState(actionResult: .capture)
                    }
                } else {
                    self.markerManager.reassign(sourceMarker, to: destinationNode, player: self.currentPlayer)
                    self.updateGameState(actionResult: .move)
                }
        case .none:
            break
        }
    }

    func handleScore() async throws {
        switch selectedMarker {
        case .existing(let sourceMarker):
            try self.discardRoll(name: .bottomRightVertex)
            gameEngine.clearAllTargetNodes()

            gameStateManager.startAnimating()

            try await self.markerManager.move(sourceMarker, to: .bottomRightVertex, using: self.gameEngine)
            try self.markerManager.handleScore(player: self.currentPlayer)

            markerManager.setSelectedMarker(.none)
            self.updateGameState(actionResult: .score)
        default:
            throw MarkerActionError.invalidSelectedMarker(selectedMarker)
        }
    }
}

// MARK: - MarkerManager
extension AppModel {
    func remainingMarkerCount(for player: Player) -> Int {
        player.score - markerManager.markerCount(for: player)
    }

    // User can only tap markers that are placed on one of the target nodes.
    private func onTargetNode(_ marker: Entity) throws -> Bool {
        let node = try markerManager.findNode(for: marker)
        return gameEngine.targetNodes.contains { $0.name == node.name }
    }

    func checkForLanding() {
        rollManager.checkForLanding()
    }
}

// MARK: - Debug
extension AppModel {
    func debugRoll(_ result: Yoot) {
        gameStateManager.startRolling()

        if result.canThrowAgain {
            gameStateManager.setCanThrowAgain()
        } else {
            gameStateManager.unsetCanThrowAgain()
        }

        gameStateManager.finishRolling()
        rollManager.result.append(result)
    }
}

// MARK: - RollManager
extension AppModel {
    func discardRoll(for destinationNode: Node) throws {
        guard let targetNode = self.gameEngine.getTargetNode(nodeName: destinationNode.name) else {
            throw MarkerActionError.targetNodeMissing(node: destinationNode)
        }
        rollManager.discardRoll(for: targetNode)
    }

    func discardRoll(name: NodeName) throws {
        guard let targetNode = self.gameEngine.getTargetNode(nodeName: name) else {
            throw MarkerActionError.targetNodeMissing(node: .bottomRightVertex)
        }
        rollManager.discardRoll(for: targetNode)
    }
}

// MARK: - GameStateManager
private extension AppModel {
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
        case .score:
            if isGameOver() {
                gameStateManager.endGame(winner: currentPlayer)
            } else {
                handlePostMoveOrScore()
            }

        case .move, .piggyback:
            handlePostMoveOrScore()

        case .capture:
            gameStateManager.setCanThrowAgain()
            if result.isEmpty {
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

    func handlePostMoveOrScore() {
        if gameStateManager.playerCanThrowAgain {
            if result.isEmpty {
                gameStateManager.canRollAgain()
            } else {
                gameStateManager.canRollOrMove()
            }
        } else {
            if result.isEmpty {
                gameStateManager.finishTurn()
                gameStateManager.switchTurn()
            } else {
                gameStateManager.canMoveAgain()
            }
        }
    }

    func isGameOver() -> Bool {
        return currentPlayer.score > 0 ? false : true
    }
}

extension AppModel {
    var shouldDisplayScoreButton: Bool {
        targetNodes.contains { $0.name == .bottomRightVertex && $0.isScoreable }
    }

    var attachmentsProvider: AttachmentsProvider {
        markerManager.attachmentsProvider
    }
}

extension AppModel: MarkerManagerDelegate {
    func didTapPromotedMarkerLevel(marker: Entity) {
        if !result.isEmpty {
            self.emit(event: .tapMarker(marker))
        }
    }
}

@MainActor
extension AppModel: @preconcurrency YootRollDelegate {
    func yootRollDidStartRoll() {
        gameStateManager.startRolling()
    }

    func yootRollDidFinishRoll() {
        gameStateManager.finishRolling()
    }

    func yootRollDidRollDouble() {
        gameStateManager.setCanThrowAgain()
    }
}

extension AppModel {
    func setYootThrowBoard(_ board: Entity) {
        rollManager.yootThrowBoard = board
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
