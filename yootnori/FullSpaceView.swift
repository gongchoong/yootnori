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
    var body: some View {
        VStack(spacing: 12) {
            DebugMainView()
                .frame(width: gameBoardSize, height: gameBoardSize * 0.5)
            Spacer()
            HStack {
                GameView()
            }
        }
        .frame(width: self.gameBoardSize * 2, height: self.gameBoardSize)
        .frame(depth: self.gameBoardSize)
    }
}

private extension FullSpaceView {
    private var gameBoardSize: CGFloat {
        return Dimensions.Screen.totalSize(self.physicalMetrics)
    }
}

#Preview {
    FullSpaceView()
}
