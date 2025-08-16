//
//  DebugMainView.swift
//  yootnori
//
//  Created by David Lee on 10/20/24.
//

import SwiftUI

struct DebugMainView: View {
    @EnvironmentObject var model: AppModel
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
            .disabled(model.gameState != .waitingForRoll && model.gameState != .waitingForRollOrSelect)

            Text(String(describing: model.yootRollSteps))
                .font(.system(size: 40))

            Button {
                markerButtonTapped()
            } label: {
                Text("\(model.availableMarkerCount(for: model.currentTurn))x")
                    .font(.system(size: 40))
            }
            .foregroundStyle(model.selectedMarker == .new ? Color.accentColor : .white)
            .background(model.selectedMarker == .new ? Color.white : Color.accentColor)
            .clipShape(Capsule())
            .animation(.easeInOut, value: model.selectedMarker == .new)
            .disabled(model.gameState != .waitingForSelect && model.gameState != .waitingForRollOrSelect && model.gameState != .waitingForMove)
        }
    }
}

#Preview {
    DebugMainView(rollButtonTapped: {_ in }, markerButtonTapped: {})
}
