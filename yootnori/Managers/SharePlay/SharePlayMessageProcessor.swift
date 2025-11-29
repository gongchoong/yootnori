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
        case .assignPlayer:
            let participantIDs = session.activeParticipants
                    .map(\.id)
                    .sorted { $0.uuidString < $1.uuidString }

            try await delegate.sharePlayManager(
                didAssignPlayersWith: participantIDs,
                localParticipantID: session.localParticipant.id
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
