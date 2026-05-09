////
////  SharePlayManagerMock.swift
////  yootnori
////
////  Created by David Lee on 9/27/25.
////
//
//import Foundation
//import Combine
//import GroupActivities
//import SharePlayMock
//
//
//
//class SharePlayManagerMock: SharePlayManagerProtocol {
//
//    @Published var sharePlaySession: GroupSessionMock<AppGroupActivityMock>?
//    var sharePlayMessenger: GroupSessionMessengerMock?
//    private let messageProcessor = SharePlayMessageProcessor()
//    weak var delegate: SharePlayManagerDelegate?
//
//    private var tasks = Set<Task<Void, Never>>()
//    private var subscriptions = Set<AnyCancellable>()
//    private var gameStarted: Bool = false
//
//    init() {
//        SharePlayMockManager.enable(webSocketUrl: "ws://[ip]:8080/endpoint")
//    }
//
//    func startSharePlay() {
//        Task {
//            let activity = AppGroupActivityMock()
//            switch await activity.prepareForActivation() {
//            case .activationPreferred:
//                do {
//                    _ = try await activity.activate()
//                } catch {
//                    print("SharePlay unable to activate the activity: \(error)")
//                }
//            case .activationDisabled:
//                print("SharePlay group activity activation disabled")
//            case .cancelled:
//                print("SharePlay group activity activation cancelled")
//            @unknown default:
//                print("SharePlay group activity activation unknown case")
//            }
//        }
//    }
//
//    func sendMessage(_ message: GroupMessage) {
//        Task {
//            do {
//                try await sharePlayMessenger?.send(message)
//            } catch {
//                print("sendEnlargeMessage failed \(error)")
//            }
//        }
//    }
//
//    func configureGroupSessions() {
//        print("Start SharePlay mock")
//        Task { @MainActor in
//            for await session in AppGroupActivityMock.sessions() {
//                self.sharePlaySession = session
//                let messenger = GroupSessionMessengerMock(session: session)
//                self.sharePlayMessenger = messenger
//                await messageProcessor.setDelegate(self.delegate)
//
//                self.tasks.insert(
//                    Task { @MainActor in
//                        for await (message, _) in messenger.messages(of: GroupMessage.self) {
//                            do {
//                                try await messageProcessor.processMessage(
//                                    message,
//                                    session: session
//                                )
//                            } catch {
//                                print("Message processing error: \(error)")
//                            }
//
//                        }
//                    }
//                )
//
//                session.$activeParticipants
//                    .sink { [weak self] participants in
//                        guard let self else { return }
//                            // Only start game if there are 2 participants and it hasn't started yet
//                        guard participants.count == 2, !self.gameStarted else { return }
//                        self.gameStarted = true
//
//                        Task { @MainActor in
//                            try? await self.sharePlayMessenger?.send(
//                                GroupMessage(id: UUID(), sharePlayActionEvent: .assignPlayer)
//                            )
//                        }
//                    }
//                    .store(in: &self.subscriptions)
//
//                session.join()
//            }
//        }
//    }
//}
