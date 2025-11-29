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

    /// Indicates whether the Yoot roll buttons should be disabled.
    /// Enabled only when it is the local player's turn **and** the current game state
    /// expects a roll (e.g., `.waitingForRoll` or `.waitingForRollOrSelect`).
    var yootButtonDisabled: Bool {
        model.isMyTurn ? ![.waitingForRoll, .waitingForRollOrSelect].contains(model.gameState) : true
    }

    /// Indicates whether the “new marker” button should be disabled.
    /// Enabled only when it is the local player's turn **and** the game state allows
    /// selecting or placing a new marker (e.g., `.waitingForSelect`, `.waitingForRollOrSelect`, `.waitingForMove`).
    var newMarkerButtonDisabled: Bool {
        model.isMyTurn ? ![.waitingForSelect, .waitingForRollOrSelect, .waitingForMove].contains(model.gameState) : true
    }

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
            .disabled(yootButtonDisabled)

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
            .disabled(newMarkerButtonDisabled)
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
