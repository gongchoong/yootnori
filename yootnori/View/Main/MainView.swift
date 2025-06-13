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
        static var yootEntityNames: [String] = ["yoot_1", "yoot_2", "yoot_3", "yoot_4"]
    }
    @EnvironmentObject var model: AppModel
    @Environment(\.physicalMetrics) var physicalMetrics

    static let runtimeQuery = EntityQuery(where: .has(MarkerRuntimeComponent.self))
    @State private var subscriptions = [EventSubscription]()
    @State private var yootEntities: [Entity] = []

    var body: some View {
        RealityView { content, attachments in
            guard let board = attachments.entity(for: Constants.boardViewName) else { return }
            self.model.rootEntity.addChild(board)
            content.add(self.model.rootEntity)
            self.model.rootEntity.position = [0, 0, -0.4]

            guard let yootThrowBoardEntity = try? await Entity(named: Constants.yootThrowBoardName, in: realityKitContentBundle) else { return }
            content.add(yootThrowBoardEntity)

            yootThrowBoardEntity.position = [0, -0.5, 0]
            yootThrowBoardEntity.scale = [0.3,0.3,0.3]
            for name in Constants.yootEntityNames {
                if let yoot = yootThrowBoardEntity.findEntity(named: name) {
                    yootEntities.append(yoot)
                }
            }

            subscriptions.append(content.subscribe(to: ComponentEvents.DidAdd.self, componentType: MarkerComponent.self, { event in
                createLevelView(for: event.entity)
            }))
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
                .targetedToAnyEntity()
                .onEnded {
                    handleMarkerTapGesture(marker: $0.entity)
                }
        )
        .disabled(model.isLoading)
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
