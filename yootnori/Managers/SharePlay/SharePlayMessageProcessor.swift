//
//  SharePlayMessageProcessor.swift
//  yootnori
//
//  Created by David Lee on 11/22/25.
//
import GroupActivities
import SharePlayMock

actor SharePlayMessageProcessor {
    private weak var delegate: SharePlayManagerDelegate?

    func setDelegate(_ delegate: SharePlayManagerDelegate?) {
        self.delegate = delegate
    }

    /// Process a message completely before allowing the next one
    func processMessage(
        _ message: GroupMessage,
        session: GroupSessionMock<AppGroupActivityMock>
    ) async throws {
        guard let delegate = delegate else { return }

        switch message.sharePlayActionEvent {
        case .assignPlayer(let seed):
            try await delegate.sharePlayManager(
                didAssignPlayersWith: session.activeParticipants.map(\.id),
                localParticipantID: session.localParticipant.id,
                seed: seed
            )

        case .startGame:
            try await delegate.sharePlayManagerDidInitiateGameStart(snapshot: message.gameStateSnapshot)

        case .newMarkerButtonTap:
            try await delegate.sharePlayManagerDidTapNewMarkerButton(snapshot: message.gameStateSnapshot)

        case .roll(let bufferFrame, let result):
            try await delegate.sharePlayManager(didReceiveBufferFrame: bufferFrame, result: result, snapshot: message.gameStateSnapshot)

        case .debugRoll(let result):
            try await delegate.sharePlayManager(didReceiveDebugRollResult: result, snapshot: message.gameStateSnapshot)

        case .tapTile(let tile):
            try await delegate.sharePlayManager(didTapTile: tile, snapshot: message.gameStateSnapshot)

        case .tapMarker(let node):
            try await delegate.sharePlayManager(didTapMarker: node, snapshot: message.gameStateSnapshot)

        case .tapScore:
            try await delegate.sharePlayManagerDidTapScore(snapshot: message.gameStateSnapshot)
        }
    }
}
