//
//  FullSpaceView.swift
//  yootnori
//
//  Created by David Lee on 9/21/24.
//

import SwiftUI

struct FullSpaceView: View {
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    @Environment(\.physicalMetrics) var physicalMetrics
    @EnvironmentObject var model: AppModel
    private var showIntroduction = true

    var body: some View {
        ZStack {
            // Main game view is always present
            MainView()
                .environmentObject(model)
                .blur(radius: showIntroduction ? 10 : 0)
                .scaleEffect(showIntroduction ? 0.8 : 0.95)
                .animation(.easeInOut(duration: 0.5), value: showIntroduction)

            // Popup overlay
            if showIntroduction {
                IntroductoryView() {
                    model.emit(event: .startGame)
                } didTapSharePlayButton: {
                    model.emit(event: .startSharePlay)
                }
                .frame(maxWidth: 1100, maxHeight: 1200)
                .glassBackgroundEffect()
                .cornerRadius(20)
                .scaleEffect(showIntroduction ? 1.0 : 0.8)
                .opacity([.idle, .establishedSharePlay].contains(model.gameState) ? 1.0 : 0.0)
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .scale.combined(with: .opacity)
                ))
            }
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showIntroduction)
    }
}

#Preview {
    FullSpaceView()
}
