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
    case generalError
}

@MainActor
protocol ComputerAgentDelegate: AnyObject {
    func computerRoll() async throws
    func computerNewMarkerTap() async throws
    func computerExistingMarkerTap(marker: Entity) async throws
    func computerHandleMove(tile: Tile) async throws
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
                print("Computer turn error: \(error)")
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
                        try await self.delegate?.computerRoll()
                    }
                }
                print("Roll completed")

            case .placeNewMarker:
                try await delegate?.computerNewMarkerTap()
                print("New marker placed")

            case .tapExisting(let marker):
                try await delegate?.computerExistingMarkerTap(marker: marker)
                print("Tapped existing marker")

            case .move(let tile):
                try await delegate?.computerHandleMove(tile: tile)
                print("Move completed")

            case .score:
                // Score logic here
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

                // TODO: fix
                // If no capture or piggy back, just move the marker. Move to the furthest target node.
                // 1. Check if existing marker can move to corners or center
                // 2. If not, move to the furthest target node.
                let targetNodes = model.targetNodes
                return .move(try model.getTile(for: targetNodes.first!.name))

            }

            throw ComputerActionError.generalError
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

            // TODO: fix
            // If no capture or piggy back, just move the marker. Move to the furthest target node.
            // 1. Check if existing marker can move to corners or center
            // 2. If not, move to the furthest target node.
            let targetNodes = model.targetNodes
            return .move(try model.getTile(for: targetNodes.first!.name))
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

            // Calcuate target nodes for new marker
            let targetNodes = model.gameEngine.calculateTargetNodes(starting: .bottomRightVertex, for: result)
            // If a new marker can caputure a user marker
            if let _ = try findTargetNode(targetNodes, matching: { $0 != Player.computer.team }) {
                return .placeNewMarker
            }

            // If a new marker can piggyback another computer marker.
            if let _ = try findTargetNode(targetNodes, matching: { $0 == Player.computer.team }) {
                return .placeNewMarker
            }

            // TODO: fix
            // If no capture, or piggyback available, select the furthest existing marker on the board.
            return .tapExisting(trackedMarkers.first!.value)

        }

        func findTargetNode(_ targetNodes: Set<TargetNode>, matching condition: (Team) -> Bool) throws -> Node? {
            try targetNodes.lazy.compactMap { targetNode in
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

