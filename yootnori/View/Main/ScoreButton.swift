//
//  ScoreButton.swift
//  yootnori
//
//  Created by David Lee on 11/1/25.
//

import SwiftUI

struct ScoreButton: View {
    @EnvironmentObject var model: AppModel
    var action: () -> Void   // closure for button tap

    var body: some View {
        Button(action: action) {
            ZStack {
                Rectangle()
                    .fill(Color.red)
                    .aspectRatio(2.8, contentMode: .fit)
                    .cornerRadius(6) // optional nicer look

                Text("SCORE")
                    .foregroundColor(.white)
                    .font(.largeTitle)
                    .bold()
            }
        }
        .frame(width: 140, height: 60)
        .buttonStyle(.plain) // prevents SwiftUI's default blue highlight
        .opacity(model.shouldDisplayScoreButton ? 1 : 0)
        .disabled(!model.shouldDisplayScoreButton)
    }
}
