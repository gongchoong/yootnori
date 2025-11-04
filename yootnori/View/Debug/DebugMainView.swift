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

    private var shouldDisableRollButton: Bool {
        !(model.isMyTurn || [.waitingForSelect, .waitingForRollOrSelect].contains(model.gameState))
    }

    private var shouldDisableNewMarkerButton: Bool {
        !(model.isMyTurn || [.waitingForSelect, .waitingForRollOrSelect, .waitingForMove].contains(model.gameState))
    }

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
                disabled(shouldDisableRollButton)
            }

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
            disabled(shouldDisableNewMarkerButton)
        }
    }
}

#Preview {
    DebugMainView(rollButtonTapped: {_ in }, markerButtonTapped: {})
}
