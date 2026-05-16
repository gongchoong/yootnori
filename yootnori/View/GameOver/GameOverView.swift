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

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 90))
                .foregroundStyle(
                    LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom)
                )
                .shadow(color: .yellow.opacity(0.6), radius: 24)
                .scaleEffect(appeared ? 1 : 0.2)
                .opacity(appeared ? 1 : 0)

            VStack(spacing: 16) {
                Text("Game Over")
                    .font(.system(size: 48, weight: .heavy))

                HStack(spacing: 12) {
                    Circle()
                        .fill(winner.team == .black ? Color.black : Color.white)
                        .frame(width: 20, height: 20)
                        .overlay(Circle().stroke(Color.primary.opacity(0.3), lineWidth: 1))
                    Text("\(winner.name) Wins!")
                        .font(.system(size: 36, weight: .semibold))
                }
                .padding(.all, 12)
                .frame(maxWidth: .infinity)
                .background(
                    Capsule()
                        .fill(Color.yellow.opacity(0.25))
                        .shadow(color: .yellow.opacity(0.4), radius: 12)
                )

                Button(action: onRestart) {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.title2.bold())
                        Text("Play Again")
                            .font(.system(size: 34, weight: .semibold))
                    }
                    .padding(.all, 12)
                    .frame(maxWidth: .infinity)
                    .background(
                        Capsule()
                            .fill(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing))
                    )
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.all, 100)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.65).delay(0.1)) {
                appeared = true
            }
        }
    }
}

#Preview {
    GameOverView(winner: .playerA, onRestart: {})
}
