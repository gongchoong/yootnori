//
//  IntroductoryView.swift
//  yootnori
//
//  Created by David Lee on 9/21/24.
//

import SwiftUI

struct IntroductoryView: View {
    @EnvironmentObject var model: AppModel
    @State private var started: Bool = false
    var didTapStartButton: () -> Void
    var didTapSharePlayButton: () -> Void
    var didTapSinglePlayButton: () -> Void

    private var startButtonTitle: String {
        #if SHAREPLAY_MOCK
        switch model.gameState {
        case .idle:
            return "Waiting for SharePlay"
        case .establishedSharePlay:
            return model.isMyTurn ? "Start Game" : "Waiting for opponent.."
        default:
            return ""
        }
        #else
        "Start Game"
        #endif
    }

    var body: some View {
        VStack(spacing: 25) {
            
            // Logo Section
            VStack(spacing: 20) {
                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 70))
                    .foregroundColor(.primary)

                Text("YOOTNORI")
                    .font(.system(size: 56, weight: .bold))
                    .foregroundColor(.primary)
            }

            // Instructions
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    gameInstructionSection(
                        title: "🎯 Game Overview",
                        content: "Yootnori is a traditional Korean board game played with four wooden sticks called 'yoot'. Players race their pieces around the board based on how the sticks land when thrown."
                    )

                    gameInstructionSection(
                        title: "🎲 How to Play",
                        content: """
                        1. Each player takes turns throwing the four yoot sticks
                        2. The way the sticks land determines how many spaces to move:
                           • All flat sides up (모): Move 5 spaces + extra turn
                           • One rounded side up (도): Move 1 space
                           • Two rounded sides up (개): Move 2 spaces
                           • Three rounded sides up (걸): Move 3 spaces
                           • All rounded sides up (윷): Move 4 spaces + extra turn
                        3. Move your pieces clockwise around the board
                        4. Land on an opponent's piece to send it back to start
                        5. First player to get all pieces home wins!
                        """
                    )
                    
                    gameInstructionSection(
                        title: "⚡ Special Rules",
                        content: """
                        • Getting 모 (mo) or 윷 (yoot) gives you an extra turn
                        • You can stack your own pieces for protection
                        • Take shortcuts across the board when possible
                        • Landing on your own piece allows them to move together
                        """
                    )
                    
                    gameInstructionSection(
                        title: "🏆 Winning Strategy",
                        content: "Balance offense and defense. Protect your pieces while looking for opportunities to send opponents back to start. Use the diagonal shortcuts to reach home faster!"
                    )
                }
            }

            VStack(spacing: 15) {
                #if SHAREPLAY_MOCK
                IntroductoryViewActionButton(image: Image(systemName: "play.fill"), title: startButtonTitle) {
                    guard !started else { return }
                    started = true
                    didTapStartButton()
                }
                .disabled(!(model.gameState == .establishedSharePlay && model.isMyTurn))
                .opacity(model.gameState == .establishedSharePlay && model.isMyTurn ? 1 : 0.5)

                IntroductoryViewActionButton(image: Image(systemName: "shareplay"), title: "Share Play") {
                    didTapSharePlayButton()
                }
                .disabled(model.gameState == .establishedSharePlay)
                .opacity(model.gameState != .establishedSharePlay ? 1 : 0.5)
                #endif

                IntroductoryViewActionButton(image: Image(systemName: "play.fill"), title: "Single Play") {
                    didTapSinglePlayButton()
                }
            }
            .padding(.top, 20)
        }
        .padding(.all, 80)
    }
    
    @ViewBuilder
    private func gameInstructionSection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(.primary)
            
            Text(content)
                .font(.system(size: 32))
                .foregroundColor(.secondary)
                .lineSpacing(6)
        }
        .padding(.vertical, 8)
    }
}

fileprivate struct IntroductoryViewActionButton: View {
    var image: Image
    var title: String
    var didTapButton: () -> Void

    var body: some View {
        Button(action: {
            didTapButton()
        }) {
            HStack {
                image
                    .font(.title2)
                Text(title)
                    .font(.system(size: 36, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, minHeight: 80)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue, Color.purple]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(25)
            .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    IntroductoryView(didTapStartButton: {}, didTapSharePlayButton: {}, didTapSinglePlayButton: {})
}
