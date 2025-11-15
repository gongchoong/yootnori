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
    @EnvironmentObject var model: AppModel
    @Environment(\.physicalMetrics) var physicalMetrics
    @Environment(\.mainViewConstants) private var mainViewConstants
    @State private var sceneUpdateSubscription: EventSubscription?

    static let runtimeQuery = EntityQuery(where: .has(MarkerRuntimeComponent.self))
    @State private var subscriptions = [EventSubscription]()
    @State private var yootEntities: [Entity] = []

    private var debugMode = true

    var body: some View {
        RealityView { content, attachments in
            await createBoard(content, attachments)
            #if DEBUG_MODE
            await createDebugView(content, attachments)
            await createScoreButton(content, attachments)
            #else
            await createGameStatusView(content, attachments)
            await createYootThrowBoard(content)
            await createRollButton(content, attachments)
            await createScoreButton(content, attachments)
            #endif

            subscriptions.append(content.subscribe(to: ComponentEvents.DidAdd.self, componentType: MarkerComponent.self, { event in
                createLevelView(for: event.entity)
            }))

            // Subscribe to scene update events
            sceneUpdateSubscription = content.subscribe(to: SceneEvents.Update.self) { event in
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
            Attachment(id: mainViewConstants.boardViewName) {
                BoardView(viewModel: BoardViewModel()) { tile in
                    model.emit(event: .tapTile(tile))
                }
            }

            Attachment(id: mainViewConstants.debugViewName) {
                DebugMainView { result in
                    model.emit(event: .tapDebugRoll(result))
                } markerButtonTapped: {
                    model.emit(event: .tapNew)
                }

            }

            Attachment(id: mainViewConstants.gameStatusViewName) {
                GameStatusView(players: [.playerA, .playerB]) {
                    model.emit(event: .tapNew)
                }
            }

            Attachment(id: mainViewConstants.rollButtonName) {
                RollButton {
                    model.emit(event: .tapRoll)
                }
            }

            Attachment(id: mainViewConstants.scoreButtonName) {
                ScoreButton {
                    model.emit(event: .score)
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
                    model.emit(event: .tapMarker($0.entity))
                }
        )
        .onDisappear {
            sceneUpdateSubscription?.cancel()
        }
        .disabled(model.gameState == .animating)
        #if SHAREPLAY_MOCK
        .task {
            model.configureGroupSessions()
        }
        #endif
        .environmentObject(model)
    }
}

@MainActor
private extension MainView {
    func createBoard(_ content: RealityViewContent, _ attachments: RealityViewAttachments) async {
        guard let board = attachments.entity(for: mainViewConstants.boardViewName) else { return }
        model.rootEntity.addChild(board)
        content.add(self.model.rootEntity)
        model.rootEntity.position = mainViewConstants.boardPosition
    }

    func createDebugView(_ content: RealityViewContent, _ attachments: RealityViewAttachments) async {
        guard let debugView = attachments.entity(for: mainViewConstants.debugViewName) else { return }
        content.add(debugView)
        debugView.position = mainViewConstants.debugViewPosition
    }

    func createGameStatusView(_ content: RealityViewContent, _ attachments: RealityViewAttachments) async {
        guard let gameStatusView = attachments.entity(for: mainViewConstants.gameStatusViewName) else { return }
        content.add(gameStatusView)
        gameStatusView.position = mainViewConstants.gameStatusViewPosition
    }

    func createYootThrowBoard(_ content: RealityViewContent) async {
        guard let board = try? await Entity(named: mainViewConstants.yootThrowBoardName, in: realityKitContentBundle) else { return }
        content.add(board)
        board.position = mainViewConstants.throwBoardPosition
        board.scale = mainViewConstants.throwBoardScale
        model.setYootThrowBoard(board)
    }

    func createRollButton(_ content: RealityViewContent, _ attachments: RealityViewAttachments) async {
        guard let rollButton = attachments.entity(for: mainViewConstants.rollButtonName) else { return }
        content.add(rollButton)
        rollButton.position = mainViewConstants.rollButtonPosition
    }

    func createScoreButton(_ content: RealityViewContent, _ attachments: RealityViewAttachments) async {
        guard let scoreButton = attachments.entity(for: mainViewConstants.scoreButtonName) else { return }
        content.add(scoreButton)
        scoreButton.position = mainViewConstants.scoreButtonPosition
    }
}

private extension MainView {
    func createLevelView(for entity: Entity) {
        guard entity.components[MarkerRuntimeComponent.self] == nil else { return }

        guard let markerComponent = entity.components[MarkerComponent.self] else { return }
        let tag: ObjectIdentifier = entity.id
        let view = MarkerLevelView(tapAction: {
            model.emit(event: .tapMarker(entity))
        }, level: markerComponent.level, team: Team(rawValue: markerComponent.team) ?? .black)
            .tag(tag)

        entity.components[MarkerRuntimeComponent.self] = MarkerRuntimeComponent(attachmentTag: entity.id)

        model.attachmentsProvider.attachments[tag] = AnyView(view)
    }

    func handleMarkerTapGesture(marker: Entity) {
        model.emit(event: .tapMarker(marker))
    }
}

#Preview {
    MainView()
}
