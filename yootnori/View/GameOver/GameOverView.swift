//
//  GameOverView.swift
//  yootnori
//
//  Created by David Lee on 5/9/26.
//

import SwiftUI

struct GameOverView: View {
    let winner: Player
    let onRestart: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 12) {
                Text("Game Over")
                    .font(.system(size: 48, weight: .bold))
                Text("\(winner.name) Wins!")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(.secondary)
            }

            Button(action: onRestart) {
                Text("Restart")
                    .font(.title2.bold())
                    .padding(.horizontal, 48)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(56)
    }
}
