//
//  GroupActivityManager.swift
//  yootnori
//
//  Created by David Lee on 9/27/25.
//

import Foundation
import Combine
import GroupActivities

protocol SharePlayManagerProtocol {
    func startSharePlay()
    func configureGroupSessions()
}

class SharePlayManager: SharePlayManagerProtocol {

    @Published var sharePlaySession: GroupSession<AppGroupActivity>?
    var sharePlayMessenger: GroupSessionMessenger?
    var tasks = Set<Task<Void, Never>>()

    func startSharePlay() {
        Task {
            let activity = AppGroupActivity()
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

    func configureGroupSessions() {
        print("configuring from debug")
        Task {
            for await session in AppGroupActivity.sessions() {
                self.sharePlaySession = session
                let messenger = GroupSessionMessenger(session: session)
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
