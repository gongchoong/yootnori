//
//  GameView.swift
//  yootnori
//
//  Created by David Lee on 9/21/24.
//

import SwiftUI
import RealityKit

struct GameView: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.physicalMetrics) var physicalMetrics
    
    var body: some View {
        RealityView { content, attachments in
            attachments.entity(for: "board")!.name = "board"
            self.model.rootEntity.addChild(attachments.entity(for: "board")!)
            content.add(self.model.rootEntity)
        } attachments: {
            Attachment(id: "board") {
                BoardView()
                    .environmentObject(model)
            }
        }
        .gesture(
            TapGesture()
                .targetedToAnyEntity()
                .onEnded {
                    self.model.perform(action: .tapMarker($0.entity))
                }
        )
        .frame(
            width: Dimensions.Screen.totalSize(self.physicalMetrics),
            height: 0
        )
    }
}

#Preview {
    GameView()
}
