//
//  SharePlayGameStateManager.swift
//  yootnori
//
//  Created by David Lee on 11/2/25.
//
import Foundation

enum GameStateManagerError: Error {
    case playerRoleNotFound
    case invalidState(String, GameState)
    case invalidParticipantCount
}

@MainActor
final class SharePlayGameStateManager: ObservableObject {
    @Published private(set) var state: GameState = .idle
    @Published private(set) var currentTurn: Player = .none {
        didSet {
            isMyTurn = currentTurn == myPlayer
        }
    }
    @Published private(set) var shouldRollAgain: Bool = false
    @Published private(set) var isMyTurn: Bool = false
    private(set) var myPlayer: Player = .none

    // MARK: - State Transitions
    func establishSharePlay() throws {
        guard state == .idle else { throw GameStateManagerError.invalidState(#function, state) }
        transition(to: .establishedSharePlay)
        currentTurn = .playerA
    }

    func startGame() throws {
        guard state == .establishedSharePlay else { throw GameStateManagerError.invalidState(#function, state) }
        transition(to: .waitingForRoll)
    }

    func startSinglePlay() throws {
        guard state == .idle else { throw GameStateManagerError.invalidState(#function, state) }
        myPlayer = .playerA
        currentTurn = myPlayer
        transition(to: .waitingForRoll)
    }

    func startRolling() throws {
        guard [.waitingForRoll, .waitingForRollOrSelect].contains(state) else { throw GameStateManagerError.invalidState(#function, state) }
        shouldRollAgain = false
        transition(to: .rolling)
    }

    func finishRolling() throws {
        guard state == .rolling else { throw GameStateManagerError.invalidState(#function, state) }
        transition(to: shouldRollAgain ? .waitingForRollOrSelect : .waitingForSelect)
    }

    func selectMarker() throws {
        guard [.waitingForSelect, .waitingForRollOrSelect].contains(state) else { throw GameStateManagerError.invalidState(#function, state) }
        transition(to: .waitingForMove)
    }

    func startAnimating() throws {
        guard state == .waitingForMove else { throw GameStateManagerError.invalidState(#function, state) }
        transition(to: .animating)
    }

    func canRollAgain() throws {
        guard state == .animating else { throw GameStateManagerError.invalidState(#function, state) }
        transition(to: .waitingForRoll)
    }

    func canMoveAgain() throws {
        guard state == .animating else { throw GameStateManagerError.invalidState(#function, state) }
        transition(to: .waitingForSelect)
    }

    func canRollOrMove() throws {
        guard [.animating, .waitingForMove].contains(state) else { throw GameStateManagerError.invalidState(#function, state) }
        transition(to: .waitingForRollOrSelect)
    }

    func unselectMarker() throws {
        guard state == .waitingForMove else { throw GameStateManagerError.invalidState(#function, state) }
        transition(to: .waitingForSelect)
    }

    func finishTurn() throws {
        guard state == .animating else { throw GameStateManagerError.invalidState(#function, state) }
        transition(to: .turnEnded)
        print("GameState: Turn finished")
    }

    func switchTurn(_ playMode: PlayMode) throws {
        guard state == .turnEnded else { throw GameStateManagerError.invalidState(#function, state) }

        switch playMode {
        case .singlePlay:
            currentTurn = currentTurn == myPlayer ? .computer : myPlayer
        case .sharePlay:
            #if SHAREPLAY_MOCK
            currentTurn = currentTurn.next
            #endif
        }

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

    func updateShouldRollAgain(_ result: Yoot) {
        shouldRollAgain = result.shouldRollAgain
    }

    func updateShouldRollAgain(_ shouldRollAgain: Bool) {
        self.shouldRollAgain = shouldRollAgain
    }
}

extension SharePlayGameStateManager {

    func createSnapshot() -> GameStateSnapshot {
        GameStateSnapshot(
            state: state,
            currentTurn: currentTurn,
            shouldRollAgain: shouldRollAgain
        )
    }

    func applySnapshot(_ snapshot: GameStateSnapshot) {
        self.state = snapshot.state
        self.currentTurn = snapshot.currentTurn
        self.shouldRollAgain = snapshot.shouldRollAgain
        self.isMyTurn = currentTurn == myPlayer
    }

    func validateState(_ expected: GameState) -> Bool {
        return state == expected
    }

    func assignPlayer(participantIDs: [UUID], localParticipantID: UUID) throws {
        guard participantIDs.count == 2 else {
            throw GameStateManagerError.invalidParticipantCount
        }

        self.myPlayer = localParticipantID == participantIDs.first ? .playerA : .playerB
    }
}
