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
    private var gameStateManager: SharePlayGameStateManager
    private let markerManager: MarkerManager
    private var gameEngine: GameEngine
    private var sharePlayManager: SharePlayManagerProtocol

    init(rollManager: YootRollManager, gameStateManager: SharePlayGameStateManager, markerManager: MarkerManager, gameEngine: GameEngine, sharePlayManager: SharePlayManagerProtocol) {
        self.rollManager = rollManager
        self.gameStateManager = gameStateManager
        self.markerManager = markerManager
        self.gameEngine = gameEngine
        self.sharePlayManager = sharePlayManager
        self.sharePlayManager.delegate = self
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
    @Published private(set) var currentTurn: Player = .none
    @Published private(set) var isMyTurn: Bool = false
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

        gameStateManager.$currentTurn
            .receive(on: RunLoop.main)
            .assign(to: &$currentTurn)

        gameEngine.$targetNodes
            .receive(on: RunLoop.main)
            .assign(to: &$targetNodes)

        markerManager.$selectedMarker
            .receive(on: RunLoop.main)
            .assign(to: &$selectedMarker)

        rollManager.$result
            .receive(on: RunLoop.main)
            .assign(to: &$result)

        gameStateManager.$isMyTurn
            .receive(on: RunLoop.main)
            .assign(to: &$isMyTurn)
    }
}

extension AppModel {
    func emit(event: ActionEvent) {
        actionEventEmitter.emit(event)
    }

    private func handleActionEvent(_ actionEvent: ActionEvent) async throws {
        switch actionEvent {
        case .startSharePlay:
            #if SHAREPLAY_MOCK
            startSharePlay()
            #endif
        case .startGame:
            #if SHAREPLAY_MOCK
            try await startGame()
            sendSharePlayMessage(.startGame)
            #else
            await startGame()
            #endif
        case .tapMarker(let marker):
            #if SHAREPLAY_MOCK
            let node = try markerManager.findNode(for: marker)
            try await handleMarkerTap(marker, updateState: true)

            sendSharePlayMessage(.tapMarker(on: node))
            #else
            try await handleMarkerTap(marker, updateState: true)
            #endif
        case .tapTile(let tile):
            #if SHAREPLAY_MOCK
            try await handleTileTap(tile, updateState: true)

            sendSharePlayMessage(.tapTile(tile))
            #else
            try await handleTileTap(tile, updateState: true)
            #endif
        case .tapNew:
            #if SHAREPLAY_MOCK
            try await handleNewMarkerTap(updateState: true)

            sendSharePlayMessage(.newMarkerButtonTap)
            #else
            await handleNewMarkerTap()
            #endif
        case .tapRoll:
            try await roll()
        case .tapDebugRoll(let result):
            #if SHAREPLAY_MOCK
            try await debugRoll(result, updateState: true)

            sendSharePlayMessage(.debugRoll(result))
            #else
            await debugRoll(result)
            #endif
        case .score:
            #if SHAREPLAY_MOCK
            try await handleScore(updateState: true)

            sendSharePlayMessage(.tapScore)
            #else
            try await handleScore(updateState: true)
            #endif
        }
    }
}

// MARK: Button tap
extension AppModel {
    func startSharePlay() {
        sharePlayManager.startSharePlay()
    }

    func startGame() async throws {
        try gameStateManager.startGame()
    }

    func roll() async throws {
        guard [.waitingForRoll, .waitingForRollOrSelect].contains(gameStateManager.state) else { return }
        try await rollManager.roll()
    }

    func handleNewMarkerTap(updateState: Bool) async throws {
        // Update game state.
        if updateState {
            switch gameStateManager.state {
            case .waitingForSelect, .waitingForRollOrSelect:
                try gameStateManager.selectMarker()
            case .waitingForMove:
                if gameStateManager.shouldRollAgain {
                    try gameStateManager.canRollOrMove()
                } else if selectedMarker == .new {
                    try gameStateManager.unselectMarker()
                }
            default:
                break
            }
        }

        // Run animation, then update markers and target nodes.
        switch selectedMarker {
        case .existing(let entity):
            await markerManager.drop(entity)
            markerManager.setSelectedMarker(.new)
            gameEngine.updateTargetNodes(for: rollManager.result)

        case .none:
            markerManager.setSelectedMarker(.new)
            gameEngine.updateTargetNodes(for: rollManager.result)

        case .new:
            markerManager.setSelectedMarker(.none)
            gameEngine.clearAllTargetNodes()
        }
    }
}

// MARK: - Entity action
private extension AppModel {
    func handleMarkerTap(_ destinationMarker: Entity, updateState: Bool) async throws {
        switch selectedMarker {
        case .existing(let sourceMarker):
                // Tapped the same marker again — just drop it to unselect.
            if destinationMarker == sourceMarker {
                markerManager.setSelectedMarker(.none)
                gameEngine.clearAllTargetNodes()

                await markerManager.drop(destinationMarker)

                if updateState {
                    try updateGameState(actionResult: .drop)
                }
            } else {
                guard try onTargetNode(destinationMarker) else { return }
                let destinationMarkerComponent = try destinationMarker.component()
                let sourceNode = try markerManager.findNode(for: sourceMarker)
                let destinationNode = try markerManager.findNode(for: destinationMarker)

                try discardRoll(for: destinationNode)
                gameEngine.clearAllTargetNodes()
                markerManager.setSelectedMarker(.none)

                if updateState {
                    try gameStateManager.startAnimating()
                }

                    // If same team, piggy back.
                if currentTurn.team.rawValue == destinationMarkerComponent.team {
                        // Move to the destination marker’s tile.
                    try await markerManager.move(sourceMarker, to: destinationNode, using: gameEngine)

                        // Ride on top of the tapped marker.
                    try await markerManager.piggyBack(rider: sourceMarker, carrier: destinationMarker)
                    markerManager.detachMarker(from: sourceNode, player: currentTurn)

                    if updateState {
                        try updateGameState(actionResult: .piggyback)
                    }
                } else {
                        // If not on the same team, capture.
                        // Move to the destination marker’s tile.
                    try await markerManager.move(sourceMarker, to: destinationNode, using: gameEngine)

                    await markerManager.capture(capturing: sourceMarker, captured: destinationMarker)
                        // Move (reassign) the existing capturing marker from its previous node to the destination node.
                    markerManager.reassign(sourceMarker, to: destinationNode, player: currentTurn)

                    if updateState {
                        try updateGameState(actionResult: .capture)
                    }
                }
            }
        case .new:
            guard remainingMarkerCount(for: currentTurn) > 0 else { return }
            guard try onTargetNode(destinationMarker) else { return }
            let destinationMarkerComponent = try destinationMarker.component()
            let destinationNode = try markerManager.findNode(for: destinationMarker)

            try discardRoll(for: destinationNode)
            gameEngine.clearAllTargetNodes()
            markerManager.setSelectedMarker(.none)

            if updateState {
                try gameStateManager.startAnimating()
            }

                // If on the same team, piggyback
            if currentTurn.team.rawValue == destinationMarkerComponent.team {
                 // Attempting to place a new marker, but tapped a marker that’s already on the board.
                 // Create a temporary marker at the START node and move it to the tapped tile.
                 // This is just for animation purposes.
                let startNode = try gameEngine.findNode(named: .bottomRightVertex)
                let sourceMarker = try await markerManager.create(at: startNode, for: currentTurn)
                try await markerManager.move(sourceMarker, to: destinationNode, using: gameEngine)

                    // Piggyback onto the existing marker.
                try await markerManager.piggyBack(rider: sourceMarker, carrier: destinationMarker)

                if updateState {
                    try updateGameState(actionResult: .piggyback)
                }
            } else {
                // If not on the same team, capture
                // Create a temporary marker at the START node and move it to the tapped tile.
                // This is just for animation purposes.
                let startNode = try gameEngine.findNode(named: .bottomRightVertex)
                let sourceMarker = try await markerManager.create(at: startNode, for: self.currentTurn)
                try await markerManager.move(sourceMarker, to: destinationNode, using: self.gameEngine)

                await markerManager.capture(capturing: sourceMarker, captured: destinationMarker)
                    // Assign the new marker to the destination node.
                markerManager.assign(marker: sourceMarker, to: destinationNode, player: currentTurn)

                if updateState {
                    try updateGameState(actionResult: .capture)
                }
            }
        case .none:
            guard let markerComponent = destinationMarker.components[MarkerComponent.self] else {
                throw MarkerActionError.markerComponentMissing(entity: destinationMarker)
            }
                // Only allow selecting markers that belong to the current player's team; ignore taps on opponent markers
            if currentTurn.team == Team(rawValue: markerComponent.team) &&
                [.waitingForRollOrSelect, .waitingForSelect].contains(gameStateManager.state) {
                // No marker was selected — now selecting the tapped existing marker on the board.
//                try gameStateManager.selectMarker()
                await markerManager.elevate(entity: destinationMarker)
                markerManager.setSelectedMarker(.existing(destinationMarker))

                // Show valid target tiles based on this marker's position.
                let node = try markerManager.findNode(for: destinationMarker)
                gameEngine.updateTargetNodes(starting: node.name, for: rollManager.result)

                if updateState {
                    try updateGameState(actionResult: .lift)
                }
            }
        }
    }

    func handleTileTap(_ tile: Tile, updateState: Bool) async throws {
        let destinationNode = try gameEngine.findNode(named: tile.nodeName)
        // Proceed only when user tapped a tile that's a target node.
        // Else, return.
        guard onTargetNode(destinationNode) else { return }
        switch selectedMarker {
        case .new:
            guard remainingMarkerCount(for: currentTurn) > 0 else { return }

            try discardRoll(for: destinationNode)
            gameEngine.clearAllTargetNodes()
            markerManager.setSelectedMarker(.none)

            if updateState {
                try gameStateManager.startAnimating()
            }

            let sourceMarker = try await markerManager.create(at: .bottomRightVertex, for: self.currentTurn)
            try await markerManager.move(sourceMarker, to: destinationNode, using: self.gameEngine)

            if let destinationMarker = markerManager.findMarker(for: destinationNode) {
                // If a marker already exists on the selected tile, find which player
                // the marker belongs to.
                guard let player = markerManager.player(for: destinationMarker) else {
                    throw MarkerActionError.playerNotFound(entity: destinationMarker)
                }
                // If on the same team, piggyback.
                if player.team == currentTurn.team {
                    try await markerManager.piggyBack(rider: sourceMarker, carrier: destinationMarker)

                    if updateState {
                        try updateGameState(actionResult: .piggyback)
                    }
                } else {
                    // If not on the same team, capture.
                    await markerManager.capture(capturing: sourceMarker, captured: destinationMarker)

                    // Assign the new marker to the destination node.
                    markerManager.assign(marker: sourceMarker, to: destinationNode, player: currentTurn)
                    if updateState {
                        try updateGameState(actionResult: .capture)
                    }
                }
            } else {
                // If no marker is on the tile, just move.
                markerManager.assign(marker: sourceMarker, to: destinationNode, player: currentTurn)

                if updateState {
                    try updateGameState(actionResult: .move)
                }
            }
        case .existing(let sourceMarker):
            // Locate the current position of the selected marker.
            let startingNode = try markerManager.findNode(for: sourceMarker)

            try discardRoll(for: destinationNode)
            gameEngine.clearAllTargetNodes()
            markerManager.setSelectedMarker(.none)

            if updateState {
                try gameStateManager.startAnimating()
            }

                // Move the selected marker to the tapped tile.
                try await markerManager.move(sourceMarker, to: destinationNode, using: self.gameEngine)

                // If another marker already occupies the tile, piggyback onto it;
                // otherwise, reassign the marker to the new location.
                if let destinationMarker = markerManager.findMarker(for: destinationNode) {
                    // If a marker already exists on the selected tile, find which player
                    // the marker belongs to.
                    guard let player = markerManager.player(for: destinationMarker) else {
                        throw MarkerActionError.playerNotFound(entity: destinationMarker)
                    }
                    // If on the same team, piggy back.
                    if player.team == currentTurn.team {
                        try await markerManager.piggyBack(rider: sourceMarker, carrier: destinationMarker)
                        markerManager.detachMarker(from: startingNode, player: currentTurn)

                        if updateState {
                            try updateGameState(actionResult: .piggyback)
                        }
                    } else {
                        // If not on the same team, capture.
                        await markerManager.capture(capturing: sourceMarker, captured: destinationMarker)

                        // Move (reassign) the existing capturing marker from its previous node to the destination node.
                        markerManager.reassign(sourceMarker, to: destinationNode, player: currentTurn)

                        if updateState {
                            try updateGameState(actionResult: .capture)
                        }
                    }
                } else {
                    self.markerManager.reassign(sourceMarker, to: destinationNode, player: self.currentTurn)

                    if updateState {
                        try updateGameState(actionResult: .move)
                    }
                }
        case .none:
            break
        }
    }

    func handleScore(updateState: Bool) async throws {
        switch selectedMarker {
        case .existing(let sourceMarker):
            try self.discardRoll(name: .bottomRightVertex)
            gameEngine.clearAllTargetNodes()

            if updateState {
                try gameStateManager.startAnimating()
            }

            try await self.markerManager.move(sourceMarker, to: .bottomRightVertex, using: self.gameEngine)
            try self.markerManager.handleScore(player: self.currentTurn)

            markerManager.setSelectedMarker(.none)

            if updateState {
                try updateGameState(actionResult: .score)
            }
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

    // User can only tap tiles that are target nodes.
    private func onTargetNode(_ node: Node) -> Bool {
        return gameEngine.targetNodes.contains { $0.name == node.name }
    }

    func checkForLanding() {
        do {
            try rollManager.checkForLanding()
        } catch {
            fatalError()
        }
    }
}

// MARK: - Debug
extension AppModel {
    func debugRoll(_ result: Yoot, updateState: Bool) async throws {
        if updateState {
            try gameStateManager.startRolling()
            gameStateManager.updateShouldRollAgain(result)
            try gameStateManager.finishRolling()
        }
        rollManager.result.append(result)
    }
}

// MARK: - RollManager
extension AppModel {
    func discardRoll(for destinationNode: Node) throws {
        guard let targetNode = self.gameEngine.getTargetNode(nodeName: destinationNode.name) else {
            throw MarkerActionError.targetNodeMissing(node: destinationNode)
        }
        try rollManager.discardRoll(for: targetNode)
    }

    func discardRoll(name: NodeName) throws {
        guard let targetNode = self.gameEngine.getTargetNode(nodeName: name) else {
            throw MarkerActionError.targetNodeMissing(node: .bottomRightVertex)
        }
        try rollManager.discardRoll(for: targetNode)
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

    func updateGameState(actionResult: ActionResult) throws {
        switch actionResult {
        case .score:
            if isGameOver() {
                gameStateManager.endGame(winner: currentTurn)
            } else {
                try handlePostMoveOrScore()
            }

        case .move, .piggyback:
            try handlePostMoveOrScore()

        case .capture:
            gameStateManager.updateShouldRollAgain(true)
            if rollManager.result.isEmpty {
                try gameStateManager.canRollAgain()
            } else {
                try gameStateManager.canRollOrMove()
            }

        case .lift:
            try gameStateManager.selectMarker()

        case .drop:
            if gameStateManager.shouldRollAgain {
                try gameStateManager.canRollOrMove()
            } else {
                try gameStateManager.unselectMarker()
            }
        }
    }

    func handlePostMoveOrScore() throws {
        if gameStateManager.shouldRollAgain {
            if rollManager.result.isEmpty {
                try gameStateManager.canRollAgain()
            } else {
                try gameStateManager.canRollOrMove()
            }
        } else {
            if rollManager.result.isEmpty {
                try gameStateManager.finishTurn()
                try gameStateManager.switchTurn()
            } else {
                try gameStateManager.canMoveAgain()
            }
        }
    }

    func isGameOver() -> Bool {
        return currentTurn.score > 0 ? false : true
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
        if !rollManager.result.isEmpty {
            self.emit(event: .tapMarker(marker))
        }
    }
}

@MainActor
extension AppModel: YootRollDelegate {

    func yootRollDidStartRoll() throws {
        try gameStateManager.startRolling()
    }

    func yootRollDidFinishRoll() throws {
        try gameStateManager.finishRolling()
    }

    func yootRollDidFinishRoll(with buffer: [ThrowFrame], result: Yoot) throws {
        gameStateManager.updateShouldRollAgain(result)
        try gameStateManager.finishRolling()

        sendSharePlayMessage(.roll(bufferFrame: buffer, result: result))
    }
}

extension AppModel {
    func setYootThrowBoard(_ board: Entity) {
        rollManager.yootThrowBoard = board
    }
}

// MARK: - Group Activity
extension AppModel {
    func configureGroupSessions() {
        self.sharePlayManager.configureGroupSessions()
    }

    func sendSharePlayMessage(_ event: SharePlayActionEvent) {
        let message = GroupMessage(id: UUID(), sharePlayActionEvent: event, gameStateSnapshot: gameStateManager.createSnapshot())
        self.sharePlayManager.sendMessage(message)
    }
}

extension AppModel: @MainActor SharePlayManagerDelegate {

    func sharePlayManager(didAssignPlayersWith participantIDs: [UUID], localParticipantID: UUID) async throws {
        guard gameStateManager.myPlayer == .none else { return }
        try gameStateManager.assignPlayer(participantIDs: participantIDs, localParticipantID: localParticipantID)
        try gameStateManager.establishSharePlay()
    }

    func sharePlayManager(didReceiveBufferFrame bufferFrame: [ThrowFrame], result: Yoot, snapshot: GameStateSnapshot) async throws {
        if !isMyTurn {
            try await rollManager.replayThrowFromNetwork(bufferFrame: bufferFrame)

            rollManager.result.append(result)
            gameStateManager.applySnapshot(snapshot)
        }
    }

    func sharePlayManager(didReceiveDebugRollResult result: Yoot, snapshot: GameStateSnapshot) async throws {
        if !isMyTurn {
            try await debugRoll(result, updateState: false)

            gameStateManager.applySnapshot(snapshot)
        }
    }

    func sharePlayManagerDidInitiateGameStart(snapshot: GameStateSnapshot) async throws {
        if !isMyTurn {
            try gameStateManager.startGame()

            gameStateManager.applySnapshot(snapshot)
        }
    }

    func sharePlayManagerDidTapNewMarkerButton(snapshot: GameStateSnapshot) async throws {
        if !isMyTurn {
            try await handleNewMarkerTap(updateState: false)

            gameStateManager.applySnapshot(snapshot)
        }
    }

    func sharePlayManager(didTapTile tile: Tile, snapshot: GameStateSnapshot) async throws {
        if !isMyTurn {
            try await handleTileTap(tile, updateState: false)

            gameStateManager.applySnapshot(snapshot)
        }
    }

    func sharePlayManager(didTapMarker node: Node, snapshot: GameStateSnapshot) async throws {
        if !isMyTurn {
            guard let marker = markerManager.findMarker(for: node) else { return }
            try await handleMarkerTap(marker, updateState: false)

            gameStateManager.applySnapshot(snapshot)
        }
    }

    func sharePlayManagerDidTapScore(snapshot: GameStateSnapshot) async throws {
        if !isMyTurn {
            try await handleScore(updateState: false)

            gameStateManager.applySnapshot(snapshot)
        }
    }
}
