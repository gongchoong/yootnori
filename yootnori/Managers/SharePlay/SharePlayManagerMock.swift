//
//  SharePlayManagerMock.swift
//  yootnori
//
//  Created by David Lee on 9/27/25.
//

#if MOCK
import Foundation
import Combine
import GroupActivities
import SharePlayMock

class SharePlayManagerMock: SharePlayManagerProtocol {

    @Published var sharePlaySession: GroupSessionMock<AppGroupActivityMock>?
    var sharePlayMessenger: GroupSessionMessengerMock?
    var tasks = Set<Task<Void, Never>>()

    init() {
        // SharePlayMockManager.enable(webSocketUrl: "ws://[ip_address]:8080/endpoint")
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
                            print("message \(message.id) \(message.message)")
                        }
                    }
                )

//                session.$activeParticipants
//                    .sink {
//                        let newParticipants = $0.subtracting(session.activeParticipants)
//                        Task { @MainActor in
//                            try? await messenger.send(EnlargeMessage(enlarged: self.enlarged),
//                                                      to: .only(newParticipants))
//                        }
//                    }
//                    .store(in: &self.subscriptions)
//
//                session.$state
//                    .sink {
//                        if case .invalidated = $0 {
//                            self.sharePlayMessenger = nil
//                            self.tasks.forEach { $0.cancel() }
//                            self.tasks = []
//                            self.subscriptions = []
//                            self.sharePlaySession = nil
//                            self.sharePlayEnabled = false
//                        }
//                    }
//                    .store(in: &self.subscriptions)

                session.join()
            }
        }
    }
}
#endif
