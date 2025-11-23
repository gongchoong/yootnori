//
//  Message.swift
//  yootnori
//
//  Created by David Lee on 9/27/25.
//

import Foundation

enum SharePlayActionEvent: Codable {
    case assignPlayer(_ seed: UInt64)
    case startGame
    case newMarkerButtonTap
    case debugRoll(_ result: Yoot)
    case tapTile(_ tile: Tile)
    case tapMarker(on: Node)
    case tapScore
    case roll(bufferFrame: [ThrowFrame], result: Yoot)
}

struct GameStateSnapshot: Codable {
    let state: GameState
    let currentTurn: Player
    let shouldRollAgain: Bool
}

extension GameStateSnapshot {
    static let `default` = GameStateSnapshot(
        state: .idle,
        currentTurn: .none,
        shouldRollAgain: false
    )
}

struct GroupMessage: Codable {
    let id: UUID
    let sharePlayActionEvent: SharePlayActionEvent
    let gameStateSnapshot: GameStateSnapshot

    init(
        id: UUID,
        sharePlayActionEvent: SharePlayActionEvent,
        gameStateSnapshot: GameStateSnapshot = .default
    ) {
        self.id = id
        self.sharePlayActionEvent = sharePlayActionEvent
        self.gameStateSnapshot = gameStateSnapshot
    }
}
