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
    @State private var showIntroduction = true
    
    var body: some View {
        ZStack {
            if showIntroduction {
                IntroductoryView(showIntro: $showIntroduction)
            } else {
                MainView()
                    .environmentObject(model)
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .animation(.easeInOut(duration: 0.5), value: showIntroduction)
    }
}

#Preview {
    FullSpaceView()
}
