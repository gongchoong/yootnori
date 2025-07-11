//
//  PlayerTurnMonitor.swift
//  yootnori
//
//  Created by David Lee on 7/7/25.
//

@MainActor
class PlayerTurnDetectionService {
    private var continuation: AsyncStream<Player>.Continuation?
    private(set) var currentTurn: Player = .none

    func startMonitoring() -> AsyncStream<Player> {
        AsyncStream { continuation in
            self.continuation = continuation

            continuation.onTermination = { _ in
                Task { @MainActor in
                    self.continuation = nil
                }
            }
        }
    }

    func detectTurn(player: Player) {
        currentTurn = player
        continuation?.yield(player)
    }

    // Method to finish the stream
    func stopMonitoring() {
        continuation?.finish()
        continuation = nil
    }
}

@MainActor
class PlayerTurnMonitor {
    static let service = PlayerTurnDetectionService()

    static var turns: AsyncStream<Player> {
        return service.startMonitoring()
    }

    static var currentTurn: Player {
        return service.currentTurn
    }

    static var hasStarted: Bool {
        return currentTurn != .none
    }

    static func detectTurn(player: Player) {
        service.detectTurn(player: player)
    }

    static func switchTurn() {
        service.detectTurn(player: currentTurn.opponent)
    }

    static func stopMonitoring() {
        service.stopMonitoring()
    }
}
