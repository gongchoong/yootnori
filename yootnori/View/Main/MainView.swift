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
        static var yootNames: [String] = ["yoot_1", "yoot_2", "yoot_3", "yoot_4"]
    }

    @EnvironmentObject var model: AppModel
    @Environment(\.physicalMetrics) var physicalMetrics
    @ObservedObject var throwViewModel: ThrowViewModel
    @State private var sceneUpdateSubscription: EventSubscription?

    static let runtimeQuery = EntityQuery(where: .has(MarkerRuntimeComponent.self))
    @State private var subscriptions = [EventSubscription]()
    @State private var yootEntities: [Entity] = []

    init() {
        self.throwViewModel = ThrowViewModel()
    }

    var body: some View {
        RealityView { content, attachments in
            await createBoard(content, attachments)
            await createYootThrowBoard(content)

            subscriptions.append(content.subscribe(to: ComponentEvents.DidAdd.self, componentType: MarkerComponent.self, { event in
                createLevelView(for: event.entity)
            }))

            // Subscribe to scene update events
            sceneUpdateSubscription = content.subscribe(to: SceneEvents.Update.self) { event in
                // Only check during landing detection
                guard throwViewModel.shouldStartCheckingForLanding else { return }
                throwViewModel.checkForLanding {
                    print("FINISHED!!")
                }
            }
        } update: { content, attachments in
            model.rootEntity.scene?.performQuery(Self.runtimeQuery).forEach { entity in
                guard let component = entity.components[MarkerRuntimeComponent.self] else { return }
                guard let attachmentEntity = attachments.entity(for: component.attachmentTag) else { return }

                entity.addChild(attachmentEntity)
                attachmentEntity.setPosition([0.0, 0.0, 0.01], relativeTo: entity)
            }
        } attachments: {
            Attachment(id: Constants.boardViewName) {
                BoardView(viewModel: BoardViewModel(), action: { action in
                    model.perform(action: action)
                })
                .environmentObject(model)
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
        .gesture(
            TapGesture()
                .targetedToEntity(where: .has(YootComponent.self))
                .onEnded { _ in
                    throwViewModel.roll()
                }
        )
        .onDisappear {
            sceneUpdateSubscription?.cancel()
        }
        .disabled(model.isLoading)
    }
}

@MainActor
private extension MainView {
    func createBoard(_ content: RealityViewContent, _ attachments: RealityViewAttachments) async {
        guard let board = attachments.entity(for: Constants.boardViewName) else { return }
        model.rootEntity.addChild(board)
        content.add(self.model.rootEntity)
        model.rootEntity.position = [0, 0, -0.2]
    }

    func createYootThrowBoard(_ content: RealityViewContent) async {
        guard let yootThrowBoard = try? await Entity(named: Constants.yootThrowBoardName, in: realityKitContentBundle) else { return }
        content.add(yootThrowBoard)
        yootThrowBoard.position = [0, -0.5, 0]
        yootThrowBoard.scale = [0.2,0.2,0.2]

        let loadedEntities = await loadYootEntities(from: yootThrowBoard, named: Constants.yootNames)
        throwViewModel.entities.append(contentsOf: loadedEntities)
    }

    func loadYootEntities(from parent: Entity, named names: [String]) async -> [Entity] {
        await Task.yield() // Give RealityKit time to resolve the entity tree

        return names.compactMap { parent.findEntity(named: $0) }
    }
}

private extension MainView {
    func createLevelView(for entity: Entity) {
        guard entity.components[MarkerRuntimeComponent.self] == nil else { return }

        guard let markerComponent = entity.components[MarkerComponent.self] else { return }
        let tag: ObjectIdentifier = entity.id
        let view = MarkerLevelView(tapAction: {
            handleMarkerTapGesture(marker: entity)
        }, level: markerComponent.level)
            .tag(tag)

        entity.components[MarkerRuntimeComponent.self] = MarkerRuntimeComponent(attachmentTag: entity.id)

        model.attachmentsProvider.attachments[tag] = AnyView(view)
    }

    func handleMarkerTapGesture(marker: Entity) {
        if model.hasRemainingRoll {
            model.perform(action: .tappedMarker(marker))
        }
    }
}

#Preview {
    MainView()
}
