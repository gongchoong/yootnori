//
//  SharePlayGameStateManager.swift
//  yootnori
//
//  Created by David Lee on 11/2/25.
//
import Foundation

enum GameStateManagerError: Error {
    case playerRoleNotFound
}

@MainActor
final class SharePlayGameStateManager: ObservableObject {
    @Published private(set) var state: GameState = .idle
    @Published private(set) var currentTurn: Player = .none {
        didSet {
            isMyTurn = currentTurn == myPlayer
        }
    }
    @Published private(set) var playerCanThrowAgain: Bool = false
    @Published private(set) var isMyTurn: Bool = false
    private(set) var myPlayer: Player = .none

    // MARK: - State Transitions
    func establishSharePlay() {
        guard state == .idle else { return }
        transition(to: .establishedSharePlay)
    }

    func startGame() {
        #if !SHAREPLAY_MOCK
        myPlayer = .playerA
        #endif
        transition(to: .waitingForRoll)
    }

    func startRolling() {
        guard state == .waitingForRoll || state == .waitingForRollOrSelect else { return }
        playerCanThrowAgain = false
        transition(to: .rolling)
    }

    func finishRolling() {
        guard state == .rolling else { return }
        transition(to: playerCanThrowAgain ? .waitingForRollOrSelect : .waitingForSelect)
    }

    func selectMarker() {
        guard state == .waitingForSelect || state == .waitingForRollOrSelect else { return }
        transition(to: .waitingForMove)
    }

    func startAnimating() {
        guard state == .waitingForMove else { return }
        transition(to: .animating)
    }

    func canRollAgain() {
        guard state == .animating else { return }
        transition(to: .waitingForRoll)
    }

    func canMoveAgain() {
        guard state == .animating else { return }
        transition(to: .waitingForSelect)
    }

    func canRollOrMove() {
        guard state == .animating || state == .waitingForMove else { return }
        transition(to: .waitingForRollOrSelect)
    }

    func unselectMarker() {
        guard state == .waitingForMove else { return }
        transition(to: .waitingForSelect)
    }

    func finishTurn() {
        guard state == .animating else { return }
        transition(to: .turnEnded)
    }

    func switchTurn() {
        guard state == .turnEnded else { return }
        #if !SHAREPLAY_MOCK
        myPlayer = currentTurn
        #endif
        currentTurn = currentTurn.next
        print("GameState: Turn Changed -> \(currentTurn.team)")
        transition(to: .waitingForRoll)
    }

    func endGame(winner: Player) {
        transition(to: .gameOver(winner: winner))
        print("GameOver: Winner -> \(currentTurn.team)")
    }

    // MARK: - Helpers

    func canPerformAction(_ action: GameAction) -> Bool {
        switch (state, action) {
        case (.waitingForRoll, .roll): return true
        case (.waitingForSelect, .selectMarker): return true
        case (.waitingForSelect, .tapTile): return true
        case (.turnEnded, .switchTurn): return true
        default: return false
        }
    }

    func transition(to newState: GameState) {
        print("GameState: \(state) → \(newState)")
        self.state = newState
    }

    func setCanThrowAgain() {
        playerCanThrowAgain = true
    }

    func unsetCanThrowAgain() {
        playerCanThrowAgain = false
    }
}

extension SharePlayGameStateManager {

    func assignPlayer(participantIDs: [UUID], localParticipantID: UUID, seed: UInt64) throws {
        // Sort IDs so both devices see the same order
        let sorted = participantIDs.sorted { $0.uuidString < $1.uuidString }

        // Randomly decide who becomes playerA/playerB
        let flip = (seed % 2 == 0)

        var assignment: [UUID: Player] = [:]
        if sorted.count >= 2 {
            assignment[sorted[0]] = flip ? .playerA : .playerB
            assignment[sorted[1]] = flip ? .playerB : .playerA
        }

        guard let player = assignment[localParticipantID] else {
            throw GameStateManagerError.playerRoleNotFound
        }

        self.myPlayer = player
        self.currentTurn = .playerA
    }
}
