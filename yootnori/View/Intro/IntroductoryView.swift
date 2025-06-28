//
//  IntroductoryView.swift
//  yootnori
//
//  Created by David Lee on 9/21/24.
//

import SwiftUI

struct IntroductoryView: View {
    @Binding var showIntro: Bool
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.2)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Logo Section
                VStack(spacing: 20) {
                    // Game Logo - Replace with your actual logo
                    Image(systemName: "gamecontroller.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.primary)
                    
                    Text("YOOTNORI")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Traditional Korean Board Game")
                        .font(.system(size: 24))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                // Instructions ScrollView
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
                    .padding(.horizontal, 20)
                }
                .frame(maxHeight: 400)
                .background(Color(.systemBackground).opacity(0.8))
                .cornerRadius(15)
                .padding(.horizontal, 20)
                
                // Start Button
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showIntro = false
                    }
                }) {
                    HStack {
                        Image(systemName: "play.fill")
                            .font(.title2)
                        Text("Start Game")
                            .font(.system(size: 24, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
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
                .padding(.horizontal, 40)
                .padding(.bottom, 30)
            }
        }
    }
    
    @ViewBuilder
    private func gameInstructionSection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primary)
            
            Text(content)
                .font(.system(size: 20))
                .foregroundColor(.secondary)
                .lineSpacing(6)
        }
        .padding(.vertical, 10)
    }
}

#Preview {
    IntroductoryView(showIntro: .constant(true))
}
