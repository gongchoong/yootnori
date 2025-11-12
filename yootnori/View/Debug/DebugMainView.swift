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
                DebugYootButton(yoot: roll) { result in
                    rollButtonTapped(result)
                }
            }
            .disabled(model.gameState != .waitingForRoll && model.gameState != .waitingForRollOrSelect && !model.isMyTurn)

            Text(String(describing: model.result.map { "\($0.steps)" }))
                .font(.system(size: 40))

            Button {
                markerButtonTapped()
            } label: {
                Text("\(model.remainingMarkerCount(for: model.currentTurn))x")
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

struct DebugYootButton: View {
    var yoot: Yoot
    var buttonTapped: ((Yoot) -> Void)

    var body: some View {
        Button {
            buttonTapped(yoot)
        } label: {
            Text("Roll \(yoot.steps)")
                .font(.system(size: 40))
                .fontWeight(.bold)
        }
    }
}

#Preview {
    DebugMainView(rollButtonTapped: {_ in }, markerButtonTapped: {})
}
