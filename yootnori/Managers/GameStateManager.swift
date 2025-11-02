//
//  GameStateManager.swift
//  yootnori
//
//  Created by David Lee on 8/2/25.
//

import Foundation

enum GameState: Equatable {
    case idle
    case waitingForRoll
    case rolling
    case waitingForSelect
    case waitingForMove
    case waitingForRollOrSelect
    case animating
    case turnEnded
    case gameOver(winner: Player)
}

enum GameAction {
    case roll
    case selectMarker
    case tapTile
    case switchTurn
}

@MainActor
final class GameStateManager: ObservableObject {
    @Published private(set) var state: GameState = .idle
    @Published private(set) var currentTurn: Player = .none
    @Published private(set) var playerCanThrowAgain: Bool = false

    // MARK: - State Transitions
    func startGame() {
        currentTurn = .playerA
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
        currentTurn = currentTurn.opponent
        transition(to: .waitingForRoll)
    }

    func endGame(winner: Player) {
        transition(to: .gameOver(winner: winner))
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
