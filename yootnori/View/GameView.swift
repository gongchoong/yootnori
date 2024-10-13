//
//  GameView.swift
//  yootnori
//
//  Created by David Lee on 9/21/24.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct GameView: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.physicalMetrics) var physicalMetrics
    
    var body: some View {
        RealityView { content, attachments in
            attachments.entity(for: "board")!.name = "board"
            self.model.rootEntity.addChild(attachments.entity(for: "board")!)
            content.add(self.model.rootEntity)
            do {
                let entity = try await Entity(named: "Scene", in: RealityKitContent.realityKitContentBundle)
                let rotationAngle: Float = .pi / 2
                entity.transform.rotation = simd_quatf(angle: rotationAngle, axis: [1, 0, 0])
                entity.position = Index.inner(column: 1, row: 3).position
                entity.components.set([
                    CollisionComponent(shapes: [{
                        var value: ShapeResource = .generateBox(size: entity.visualBounds(relativeTo: nil).extents)
                        value = value.offsetBy(translation: [0, value.bounds.extents.y / 2, 0])
                        return value
                    }()]),
                    InputTargetComponent()
                ])
                self.model.rootEntity.addChild(entity)
            } catch let error {
                print(error)
            }
        } attachments: {
            Attachment(id: "board") {
                BoardView()
                    .environmentObject(model)
            }
        }
        .rotation3DEffect(.degrees(45), axis: .x)
        .frame(
            width: Dimensions.Screen.totalSize(self.physicalMetrics),
            height: 0
        )
        .frame(depth: Dimensions.Screen.totalSize(self.physicalMetrics))
    }
}

#Preview {
    GameView()
}
