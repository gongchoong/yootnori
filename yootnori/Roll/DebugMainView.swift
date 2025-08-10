//
//  DebugMainView.swift
//  yootnori
//
//  Created by David Lee on 10/20/24.
//

import SwiftUI

struct DebugMainView: View {
    @EnvironmentObject var model: AppModel
    @EnvironmentObject var gameStateManager: GameStateManager
    var rollButtonTapped: ((Yoot) -> Void)
    var markerButtonTapped: (() -> Void)

    var body: some View {
        VStack(spacing: 10) {
            Text(String(describing: model.currentTurn.team.name))
                .font(.system(size: 40))
                .fontWeight(.bold)
            ForEach(Yoot.allCases, id: \.self) { roll in
                Button {
                    rollButtonTapped(roll)
                } label: {
                    Text("Roll \(roll.steps)")
                        .font(.system(size: 40))
                        .fontWeight(.bold)
                }
            }
            .disabled(gameStateManager.state != .waitingForRoll && gameStateManager.state != .waitingForRollOrSelect)

            Text(String(describing: model.yootRollSteps))
                .font(.system(size: 40))

            Button {
                markerButtonTapped()
            } label: {
                Text("\(model.markersLeftToPlace(for: model.currentTurn))x")
                    .font(.system(size: 40))
            }
            .foregroundStyle(model.selectedMarker == .new ? Color.accentColor : .white)
            .background(model.selectedMarker == .new ? Color.white : Color.accentColor)
            .clipShape(Capsule())
            .animation(.easeInOut, value: model.selectedMarker == .new)
            .disabled(gameStateManager.state != .waitingForSelect && gameStateManager.state != .waitingForRollOrSelect && gameStateManager.state != .waitingForMove)
        }
    }
}

#Preview {
    DebugMainView(rollButtonTapped: {_ in }, markerButtonTapped: {})
}
