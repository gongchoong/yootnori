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
        _ event: SharePlayActionEvent,
        session: GroupSessionMock<AppGroupActivityMock>
    ) async throws {
        guard let delegate = delegate else { return }

        switch event {
        case .assignPlayer(let seed):
            await delegate.sharePlayManager(
                didAssignPlayersWith: session.activeParticipants.map(\.id),
                localParticipantID: session.localParticipant.id,
                seed: seed
            )

        case .established:
            await delegate.sharePlayManagerDidEstablish()

        case .startGame:
            await delegate.sharePlayManagerDidInitiateGameStart()

        case .newMarkerButtonTap:
            await delegate.sharePlayManagerDidTapNewMarkerButton()

        case .roll(let bufferFrame, let result):
            await delegate.sharePlayManager(didReceiveBufferFrame: bufferFrame, result: result)

        case .debugRoll(let result):
            await delegate.sharePlayManager(didReceiveDebugRollResult: result)

        case .tapTile(let tile):
            try await delegate.sharePlayManager(didTapTile: tile)

        case .tapMarker(let node):
            try await delegate.sharePlayManager(didTapMarker: node)

        case .tapScore:
            try await delegate.sharePlayManagerDidTapScore()
        }
    }
}
