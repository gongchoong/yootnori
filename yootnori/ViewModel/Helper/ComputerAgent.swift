//
//  ComputerAgent.swift
//  yootnori
//
//  Created by David Lee on 11/29/25.
//

import RealityKit

enum ComputerAction: Equatable {
    case idle
    case roll
    case placeNewMarker
    case tapExisting(Entity)
    case move(Tile)
    case score
    case endTurn
}

enum ComputerActionError: Error {
    /// No existing computer marker is available on the board to select or move.
    case missingExistingMarker

    /// Failed to determine the furthest valid move target for an existing marker.
    case noValidTargetForExistingMarker

    /// Failed to determine the furthest valid move target for a new marker.
    case noValidTargetForNewMarker

    /// Failed to determine a valid target when choosing between placing a new marker or selecting an existing one.
    case noValidTargetForMarkerSelection
}

@MainActor
protocol ComputerAgentDelegate: AnyObject {
    /// Triggers the UI or game logic to roll the dice/yut.
    func performComputerRoll() async throws

    /// Taps the "place new marker" UI, used when introducing a new marker onto the board.
    func tapToPlaceNewComputerMarker() async throws

    /// Taps an existing marker that belongs to the computer player, preparing it for movement.
    func tapExistingComputerMarker(marker: Entity) async throws

    /// Executes a move to the given tile for the current computer-selected marker.
    func moveComputerMarker(to tile: Tile) async throws

    /// Handles the computer's score action when scoring is available.
    func performComputerScore() async throws
}

@MainActor
class ComputerAgent {
    unowned var model: AppModel!
    weak var delegate: ComputerAgentDelegate?
    private var rollCompletionContinuation: CheckedContinuation<Void, Never>?
    private var isRunning = false
    private var currentAction: ComputerAction = .idle

    func notifyRollComplete() {
        rollCompletionContinuation?.resume()
        rollCompletionContinuation = nil
    }

    func startComputerTurn() {
        guard !isRunning else { return }
        isRunning = true

        Task {
            do {
                try await runTurn()
            } catch {
                fatalError("Computer turn error: \(error)")
            }
            isRunning = false
        }
    }

    private func runTurn() async throws {
        defer {
            currentAction = .idle
        }

        // Keep playing until it's no longer computer's turn
        while !model.isMyTurn {
            try await Task.sleep(for: .seconds(1))

            let action = try determineNextAction()
            currentAction = action

            switch action {
            case .roll:
                await withCheckedContinuation { continuation in
                    self.rollCompletionContinuation = continuation
                    Task {
                        try await self.delegate?.performComputerRoll()
                    }
                }
                print("Roll completed")

            case .placeNewMarker:
                try await delegate?.tapToPlaceNewComputerMarker()
                print("New marker placed")

            case .tapExisting(let marker):
                try await delegate?.tapExistingComputerMarker(marker: marker)
                print("Tapped existing marker")

            case .move(let tile):
                try await delegate?.moveComputerMarker(to: tile)
                print("Move completed")

            case .score:
                try await delegate?.performComputerScore()
                print("Scored")

            case .endTurn:
                print("Turn ended")
                currentAction = .idle
                return // Exit the loop
            default:
                return
            }
        }
    }

    private func determineNextAction() throws -> ComputerAction {
        print("Determining next action - State: \(model.gameState)")

        // If need to roll
        if [.waitingForRoll, .waitingForRollOrSelect].contains(model.gameState) {
            return .roll
        }

        // If can score
        if model.shouldDisplayScoreButton {
            return .score
        }

        // If no existing or new marker is selected, select one.
        switch currentAction {
        case .placeNewMarker:
            return try moveNewMarker()
        case .tapExisting:
            return try moveExistingMarker()
        default:
            return try selectExistingOrSelectNewMarker()
        }

        func moveExistingMarker() throws -> ComputerAction {
            // Check if existing marker can capture or piggyback
            if let trackedMarkers = model.trackedMarkers[.computer], !trackedMarkers.isEmpty {

                // Check if a computer marker can capture user marker.
                if let capturableNode = try findTargetNode(model.targetNodes, matching: { $0 != Player.computer.team }) {
                    return .move(try model.getTile(for: capturableNode.name))
                }

                // Check if a computer marker can piggyback another computer marker.
                if let piggytbackableNode = try findTargetNode(model.targetNodes, matching: { $0 == Player.computer.team }) {
                    return .move(try model.getTile(for: piggytbackableNode.name))
                }

                // If no capture or piggy back, just move the marker.
                // 1. Check if marker can move to corners or center
                // 2. If not, move to the furthest target node.
                let targetNodes = model.targetNodes
                let prioritizedTargetNode = targetNodes.first { $0.name.isCenterNode } ?? targetNodes.first { $0.name.isCornerNode }
                if let prioritizedTargetNode {
                    return .move(try model.getTile(for: prioritizedTargetNode.name))
                }

                guard let furtestTargetNode = targetNodes.max(by: { $0.yootRoll.steps < $1.yootRoll.steps }) else {
                    // Cannot find the furtest target node
                    throw ComputerActionError.noValidTargetForExistingMarker
                }
                return .move(try model.getTile(for: furtestTargetNode.name))

            }

            throw ComputerActionError.missingExistingMarker
        }

        func moveNewMarker() throws -> ComputerAction {
            // Check if a new computer marker can capture user marker.
            if let capturableNode = try findTargetNode(model.targetNodes, matching: { $0 != Player.computer.team }) {
                return .move(try model.getTile(for: capturableNode.name))
            }

            // Check if a new computer marker can piggyback another computer marker.
            if let piggytbackableNode = try findTargetNode(model.targetNodes, matching: { $0 == Player.computer.team }) {
                return .move(try model.getTile(for: piggytbackableNode.name))
            }

            // If no capture or piggy back, just move the marker.
            // 1. Check if marker can move to corners or center
            // 2. If not, move to the furthest target node.
            let targetNodes = model.targetNodes
            let prioritizedTargetNode = targetNodes.first { $0.name.isCenterNode } ?? targetNodes.first { $0.name.isCornerNode }
            if let prioritizedTargetNode {
                return .move(try model.getTile(for: prioritizedTargetNode.name))
            }

            guard let furtestTargetNode = targetNodes.max(by: { $0.yootRoll.steps < $1.yootRoll.steps }) else {
                // Cannot find the furtest target node
                throw ComputerActionError.noValidTargetForNewMarker
            }
            return .move(try model.getTile(for: furtestTargetNode.name))
        }

        func selectExistingOrSelectNewMarker() throws -> ComputerAction {
            // If no computer marker is on the board, tap the new marker button.
            guard let trackedMarkers = model.trackedMarkers[.computer], !trackedMarkers.isEmpty else {
                return .placeNewMarker
            }

            let result = model.result

            // Calculate target nodes for existing computer markers
            for marker in trackedMarkers {
                let nodeName = marker.key.name
                let targetNodes = model.gameEngine.calculateTargetNodes(starting: nodeName, for: result)

                // If computer marker can caputure a user marker
                if let _ = try findTargetNode(targetNodes, matching: { $0 != Player.computer.team }) {
                    return .tapExisting(marker.value)
                }

                // If a computer marker can piggyback another computer marker.
                if let _ = try findTargetNode(targetNodes, matching: { $0 == Player.computer.team }) {
                    return .tapExisting(marker.value)
                }
            }

            // If no capture, or piggyback available, select the furthest existing marker on the board.
            let furtestExistingMarker = trackedMarkers.max(by: { $0.key.name.rawValue < $1.key.name.rawValue })?.value
            guard let furtestExistingMarker else {
                throw ComputerActionError.noValidTargetForMarkerSelection
            }

            // If there's no available new marker, select the furtest existing marker
            if model.remainingMarkerCount(for: .computer) < 1 {
                return .tapExisting(furtestExistingMarker)
            }

            // Calcuate target nodes for new marker
            let targetNodes = model.gameEngine.calculateTargetNodes(starting: nil, for: result)

            // If a new marker can caputure a user marker
            if let _ = try findTargetNode(targetNodes, matching: { $0 != Player.computer.team }) {
                return .placeNewMarker
            }

            // If a new marker can piggyback another computer marker.
            if let _ = try findTargetNode(targetNodes, matching: { $0 == Player.computer.team }) {
                return .placeNewMarker
            }

            return .tapExisting(furtestExistingMarker)

        }

        func findTargetNode(_ targetNodes: Set<TargetNode>, matching condition: (Team) -> Bool) throws -> Node? {
            try targetNodes.compactMap { targetNode in
                guard let node = try? model.gameEngine.findNode(named: targetNode.name),
                      let marker = model.markerManager.findMarker(for: node),
                      let team = Team(rawValue: try marker.component().team),
                      condition(team) else {
                    return nil
                }
                return node
            }.first
        }

        // See if existing marker can move to corner or center

//        // If can move
//        if model.gameState == .waitingForMove {
//            if let targetNode = model.targetNodes.first {
//                do {
//                    return .move(try model.getTile(for: targetNode.name))
//                } catch {
//                    return .endTurn
//                }
//            }
//        }
//
//        // If no markers on board yet
//        if model.trackedMarkers[model.currentTurn] == nil {
//            return .placeNewMarker
//        }

        // Default: end turn
    }
}

