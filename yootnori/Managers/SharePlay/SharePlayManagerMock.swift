//
//  SharePlayManagerMock.swift
//  yootnori
//
//  Created by David Lee on 9/27/25.
//

import Foundation
import Combine
import GroupActivities
import SharePlayMock

protocol SharePlayManagerProtocol {
    func startSharePlay()
    func configureGroupSessions()
    func sendMessage(_ message: GroupMessage)
    var delegate: SharePlayManagerDelegate? { get set }
    var sharePlayMessenger: GroupSessionMessengerMock? { get }
}

protocol SharePlayManagerDelegate: AnyObject {
    /// Called when the SharePlay manager assigns player identities for the session.
    ///
    /// - Parameters:
    ///   - participantIDs: The ordered list of all participant IDs in the session.
    ///   - localParticipantID: The ID representing the local participant.
    ///   - seed: A seed value used to synchronize deterministic state (e.g., RNG).
    func sharePlayManager(
        didAssignPlayersWith participantIDs: [UUID],
        localParticipantID: UUID,
        seed: UInt64
    )

    /// Called when an opponent successfully establishes a SharePlay connection with the local device.
    func sharePlayManagerDidEstablish()

    /// Called when a debug roll result is received during development/testing.
    ///
    /// - Parameters:
    ///   - result: The debug-generated `Yoot` roll value.
    func sharePlayManager(didReceiveDebugRollResult result: Yoot)

    /// Called when the SharePlay session signals that gameplay should begin.
    func sharePlayManagerDidInitiateGameStart()

    func sharePlayManagerDidTapNewMarkerButton()

    func sharePlayManager(didTapTile tile: Tile)
}

class SharePlayManagerMock: SharePlayManagerProtocol {

    @Published var sharePlaySession: GroupSessionMock<AppGroupActivityMock>?
    var sharePlayMessenger: GroupSessionMessengerMock?
    weak var delegate: SharePlayManagerDelegate?

    private var tasks = Set<Task<Void, Never>>()
    private var subscriptions = Set<AnyCancellable>()
    private var gameStarted: Bool = false

    init() {
        SharePlayMockManager.enable(webSocketUrl: "ws://[ip]/endpoint")
    }

    func startSharePlay() {
        Task {
            let activity = AppGroupActivityMock()
            switch await activity.prepareForActivation() {
            case .activationPreferred:
                do {
                    _ = try await activity.activate()
                } catch {
                    print("SharePlay unable to activate the activity: \(error)")
                }
            case .activationDisabled:
                print("SharePlay group activity activation disabled")
            case .cancelled:
                print("SharePlay group activity activation cancelled")
            @unknown default:
                print("SharePlay group activity activation unknown case")
            }
        }
    }

    func sendMessage(_ message: GroupMessage) {
        Task {
            do {
                try await sharePlayMessenger?.send(message)
            } catch {
                print("sendEnlargeMessage failed \(error)")
            }
        }
    }

    func configureGroupSessions() {
        print("Start SharePlay mock")
        Task {
            for await session in AppGroupActivityMock.sessions() {
                self.sharePlaySession = session
                let messenger = GroupSessionMessengerMock(session: session)
                self.sharePlayMessenger = messenger

                self.tasks.insert(
                    Task {
                        for await (message, _) in messenger.messages(of: GroupMessage.self) {
                            switch message.sharePlayActionEvent {
                            case .assignPlayer(let seed):
                                delegate?.sharePlayManager(
                                    didAssignPlayersWith: session.activeParticipants.map(\.id),
                                    localParticipantID: session.localParticipant.id,
                                    seed: seed
                                )
                            case .established:
                                delegate?.sharePlayManagerDidEstablish()
                            case .startGame:
                                delegate?.sharePlayManagerDidInitiateGameStart()
                            case .newMarkerButtonTap:
                                delegate?.sharePlayManagerDidTapNewMarkerButton()
                            case .debugRoll(let result):
                                delegate?.sharePlayManager(didReceiveDebugRollResult: result)
                            case .tapTile(let tile):
                                delegate?.sharePlayManager(didTapTile: tile)
                            }
                        }
                    }
                )

                session.$activeParticipants
                    .sink { [weak self] participants in
                        guard let self else { return }
                            // Only start game if there are 2 participants and it hasn't started yet
                        guard participants.count == 2, !self.gameStarted else { return }
                        self.gameStarted = true

                        Task { @MainActor in
                            let seed = UInt64.random(in: 0..<UInt64.max)
                            try? await self.sharePlayMessenger?.send(
                                GroupMessage(id: UUID(), sharePlayActionEvent: .assignPlayer(seed))
                            )
                        }
                    }
                    .store(in: &self.subscriptions)

                session.join()
            }
        }
    }
}
