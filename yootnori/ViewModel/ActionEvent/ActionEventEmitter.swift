//
//  ActionEventEmitter.swift
//  yootnori
//
//  Created by David Lee on 10/21/25.
//

import RealityKit
typealias Marker = Entity

enum ActionEventError: Error {
    case invalidGameState(GameState)
}

enum ActionEvent {
    case startGame
    case tapMarker(Marker)
    case tapTile(Tile)
    case tapNew
    case tapRoll
    case tapDebugRoll(Yoot)
    case score
}

final class ActionEventEmitter {
    private var continuation: AsyncStream<ActionEvent>.Continuation?

    lazy var stream: AsyncStream<ActionEvent> = {
        AsyncStream { continuation in
            self.continuation = continuation
        }
    }()

    func emit(_ action: ActionEvent) {
        continuation?.yield(action)
    }

    func finish() {
        continuation?.finish()
    }
}
