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
    // The button is disabled while yoots are animating or if the player has no throws remaining
    var buttonDisabled: Bool {
        model.isAnimating || !model.canPlayerThrow
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
        .animation(.easeInOut(duration: 0.2), value: model.isAnimating)
        .opacity(buttonDisabled ? 0 : 1)
        .disabled(buttonDisabled)
    }
}
