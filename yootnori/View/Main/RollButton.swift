//
//  RollButton.swift
//  yootnori
//
//  Created by David Lee on 6/22/25.
//

import SwiftUI

struct RollButton: View {
    @EnvironmentObject var model: AppModel
    var didTapButton: () -> Void
    var buttonEnabled: Bool {
        guard model.isMyTurn else { return false }
        return model.gameState == .waitingForRoll || model.gameState == .waitingForRollOrSelect
    }

    var body: some View {
        Button(action: {
            didTapButton()
        }) {
            Text("ROLL")
                .font(.system(size: 50, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(width: 200, height: 80)
                .background(
                    RoundedRectangle(cornerRadius: 40)
                        .fill(Color.red.opacity(0.8))
                        .padding(.horizontal, -18)
                )
        }
        .hoverEffect(.lift)
        .animation(.easeInOut(duration: 0.2), value: model.gameState == .animating)
        .disabled(!buttonEnabled)
        .opacity(buttonEnabled ? 1 : 0)
    }
}
