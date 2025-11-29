//
//  GameStateManager.swift
//  yootnori
//
//  Created by David Lee on 8/2/25.
//

import Foundation

enum GameState: Equatable, Codable {
    case idle
    case establishedSharePlay
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
    @Published private(set) var shouldRollAgain: Bool = false

    // MARK: - State Transitions
    func startGame() {
        currentTurn = .playerA
        transition(to: .waitingForRoll)
    }
    
    func startRolling() {
        guard state == .waitingForRoll || state == .waitingForRollOrSelect else { return }
        shouldRollAgain = false
        transition(to: .rolling)
    }
    
    func finishRolling() {
        guard state == .rolling else { return }
        transition(to: shouldRollAgain ? .waitingForRollOrSelect : .waitingForSelect)
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
        currentTurn = currentTurn == .playerA ? .playerB : .playerA
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

    func updateShouldRollAgain(_ result: Yoot) {
        shouldRollAgain = result.shouldRollAgain
    }
}
