//
//  PlayerTurnViewModel.swift
//  yootnori
//
//  Created by David Lee on 7/11/25.
//

import SwiftUI
import Combine

@MainActor
class PlayerTurnViewModel: ObservableObject {
    @Published var currentTurn: Player = .none
    var currentTurnPublisher: Published<Player>.Publisher { $currentTurn }

    private var task: Task<Void, Never>?

    init() {
        task = Task {
            for await player in PlayerTurnMonitor.turns {
                self.currentTurn = player
            }
        }
    }

    deinit {
        task?.cancel()
    }

    func detectTurn(_ player: Player) {
        PlayerTurnMonitor.detectTurn(player: player)
    }

    func switchTurn() {
        PlayerTurnMonitor.switchTurn()
    }

    func stopMonitoring() {
        PlayerTurnMonitor.stopMonitoring()
    }
}
