//
//  MainView.swift
//  yootnori
//
//  Created by David Lee on 9/21/24.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct MainView: View {
    enum Constants {
        static var boardViewName: String = "Board"
        static var yootThrowBoardName: String = "YootThrowBoard"
        static var debugViewName: String = "DebugView"
        static var gameStatusViewName: String = "GameStatusView"
        static var rollButtonName: String = "RollButton"
        static var boardPosition: SIMD3<Float> = [-0.1, 0, -0.1]
        static var debugViewPosition: SIMD3<Float> = [0.3, 0, -0.1]
        static var gameStatusViewPosition: SIMD3<Float> = [0.3, 0, -0.1]
        static var throwBoardPosition: SIMD3<Float> = [0, -0.5, 0.2]
        static var throwBoardScale: SIMD3<Float> = [0.15,0.15,0.15]
    }

    @EnvironmentObject var model: AppModel
    @Environment(\.physicalMetrics) var physicalMetrics
    @State private var sceneUpdateSubscription: EventSubscription?

    static let runtimeQuery = EntityQuery(where: .has(MarkerRuntimeComponent.self))
    @State private var subscriptions = [EventSubscription]()
    @State private var yootEntities: [Entity] = []

    var body: some View {
        RealityView { content, attachments in
            await createBoard(content, attachments)
            await createGameStatusView(content, attachments)
            await createYootThrowBoard(content)
            await createRollButton(content, attachments)

            subscriptions.append(content.subscribe(to: ComponentEvents.DidAdd.self, componentType: MarkerComponent.self, { event in
                createLevelView(for: event.entity)
            }))

            // Subscribe to scene update events
            sceneUpdateSubscription = content.subscribe(to: SceneEvents.Update.self) { event in
                // Only check during landing detection
                guard model.shouldStartCheckingForLanding else { return }
                model.checkForLanding()
            }
        } update: { content, attachments in
            model.rootEntity.scene?.performQuery(Self.runtimeQuery).forEach { entity in
                guard let component = entity.components[MarkerRuntimeComponent.self] else { return }
                guard let attachmentEntity = attachments.entity(for: component.attachmentTag) else { return }

                entity.addChild(attachmentEntity)
                attachmentEntity.setPosition([0.0, 0.0, 0.02], relativeTo: entity)
            }
        } attachments: {
            Attachment(id: Constants.boardViewName) {
                BoardView(viewModel: BoardViewModel(), action: { action in
                    do {
                        try model.perform(action: action)
                    } catch let error as AppModel.MarkerActionError {
                        error.crashApp()
                    } catch {
                        fatalError("Unexpected error: \(error.localizedDescription)")
                    }
                })
            }

            Attachment(id: Constants.gameStatusViewName) {
                GameStatusView(players: [.playerA, .playerB]) {
                    model.handleNewMarkerTap()
                }
            }

            Attachment(id: Constants.rollButtonName) {
                RollButton {
                    model.roll()
                }
            }

            ForEach(model.attachmentsProvider.sortedTagViewPairs, id: \.tag) { pair in
                Attachment(id: pair.tag) {
                    pair.view
                }
            }
        }
        .gesture(
            TapGesture()
                .targetedToEntity(where: .has(MarkerComponent.self))
                .onEnded {
                    handleMarkerTapGesture(marker: $0.entity)
                }
        )
        .onDisappear {
            sceneUpdateSubscription?.cancel()
        }
        .disabled(model.isLoading)
        .environmentObject(model)
    }
}

@MainActor
private extension MainView {
    func createBoard(_ content: RealityViewContent, _ attachments: RealityViewAttachments) async {
        guard let board = attachments.entity(for: Constants.boardViewName) else { return }
        model.rootEntity.addChild(board)
        content.add(self.model.rootEntity)
        model.rootEntity.position = Constants.boardPosition
    }

    func createDebugView(_ content: RealityViewContent, _ attachments: RealityViewAttachments) async {
        guard let debugView = attachments.entity(for: Constants.debugViewName) else { return }
        content.add(debugView)
        debugView.position = Constants.debugViewPosition
    }

    func createGameStatusView(_ content: RealityViewContent, _ attachments: RealityViewAttachments) async {
        guard let gameStatusView = attachments.entity(for: Constants.gameStatusViewName) else { return }
        content.add(gameStatusView)
        gameStatusView.position = Constants.gameStatusViewPosition
    }

    func createYootThrowBoard(_ content: RealityViewContent) async {
        guard let yootThrowBoard = try? await Entity(named: Constants.yootThrowBoardName, in: realityKitContentBundle) else { return }
        model.yootThrowBoard = yootThrowBoard
        content.add(yootThrowBoard)
        yootThrowBoard.position = Constants.throwBoardPosition
        yootThrowBoard.scale = Constants.throwBoardScale
    }

    func createRollButton(_ content: RealityViewContent, _ attachments: RealityViewAttachments) async {
        guard let rollButton = attachments.entity(for: Constants.rollButtonName) else { return }
        content.add(rollButton)
        rollButton.position = [0, -0.4, 0.4]
    }
}

private extension MainView {
    func createLevelView(for entity: Entity) {
        guard entity.components[MarkerRuntimeComponent.self] == nil else { return }

        guard let markerComponent = entity.components[MarkerComponent.self] else { return }
        let tag: ObjectIdentifier = entity.id
        let view = MarkerLevelView(tapAction: {
            handleMarkerTapGesture(marker: entity)
        }, level: markerComponent.level, team: Team(rawValue: markerComponent.team) ?? .black)
            .tag(tag)

        entity.components[MarkerRuntimeComponent.self] = MarkerRuntimeComponent(attachmentTag: entity.id)

        model.attachmentsProvider.attachments[tag] = AnyView(view)
    }

    func handleMarkerTapGesture(marker: Entity) {
        if !model.isOutOfThrows {
            do {
                try model.perform(action: .tappedMarker(marker))
            } catch let error as AppModel.MarkerActionError {
                error.crashApp()
            } catch {
                fatalError("Unexpected error: \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    MainView()
}
