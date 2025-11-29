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
    /// Notifies the delegate that player identities have been assigned.
    /// - Parameters:
    ///   - participantIDs: Ordered list of all participant IDs.
    ///   - localParticipantID: The local participant’s ID.
    ///   - seed: Seed for synchronizing deterministic state.
    func sharePlayManager(didAssignPlayersWith participantIDs: [UUID], localParticipantID: UUID, seed: UInt64) async throws

    /// Notifies the delegate of a debug roll result for testing.
    /// - Parameters:
    ///   - result: The debug-generated `Yoot` roll result.
    ///   - snapshot: The corresponding game state.
    func sharePlayManager(didReceiveDebugRollResult result: Yoot, snapshot: GameStateSnapshot) async throws

    /// Notifies the delegate of a buffer frame result.
    /// - Parameters:
    ///   - bufferFrame: The resolved throw frames.
    ///   - result: The resulting `Yoot`.
    ///   - snapshot: The updated game state.
    func sharePlayManager(didReceiveBufferFrame bufferFrame: [ThrowFrame], result: Yoot, snapshot: GameStateSnapshot) async throws

    /// Notifies the delegate to start the game.
    /// - Parameter snapshot: The initial game state.
    func sharePlayManagerDidInitiateGameStart(snapshot: GameStateSnapshot) async throws

    /// Notifies the delegate that the "New Marker" button was tapped.
    /// - Parameter snapshot: The game state at the time.
    func sharePlayManagerDidTapNewMarkerButton(snapshot: GameStateSnapshot) async throws

    /// Notifies the delegate that a tile was tapped.
    /// - Parameters:
    ///   - tile: The tapped tile.
    ///   - snapshot: The current game state.
    func sharePlayManager(didTapTile tile: Tile, snapshot: GameStateSnapshot) async throws

    /// Notifies the delegate that a marker node was tapped.
    /// - Parameters:
    ///   - node: The tapped node.
    ///   - snapshot: The current game state.
    func sharePlayManager(didTapMarker node: Node, snapshot: GameStateSnapshot) async throws

    /// Notifies the delegate that the score area was tapped.
    /// - Parameter snapshot: The current game state.
    func sharePlayManagerDidTapScore(snapshot: GameStateSnapshot) async throws
}


class SharePlayManagerMock: SharePlayManagerProtocol {

    @Published var sharePlaySession: GroupSessionMock<AppGroupActivityMock>?
    var sharePlayMessenger: GroupSessionMessengerMock?
    private let messageProcessor = SharePlayMessageProcessor()
    weak var delegate: SharePlayManagerDelegate?

    private var tasks = Set<Task<Void, Never>>()
    private var subscriptions = Set<AnyCancellable>()
    private var gameStarted: Bool = false

    init() {
        SharePlayMockManager.enable(webSocketUrl: "ws://[ip]:8080/endpoint")
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
        Task { @MainActor in
            for await session in AppGroupActivityMock.sessions() {
                self.sharePlaySession = session
                let messenger = GroupSessionMessengerMock(session: session)
                self.sharePlayMessenger = messenger
                await messageProcessor.setDelegate(self.delegate)

                self.tasks.insert(
                    Task { @MainActor in
                        for await (message, _) in messenger.messages(of: GroupMessage.self) {
                            do {
                                try await messageProcessor.processMessage(
                                    message,
                                    session: session
                                )
                            } catch {
                                print("Message processing error: \(error)")
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
