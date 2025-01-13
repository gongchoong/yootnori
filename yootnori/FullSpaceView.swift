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
        GameView()
            .frame(
                width: Dimensions.Screen.totalSize(self.physicalMetrics),
                height: Dimensions.Screen.totalSize(self.physicalMetrics)
            )
            .frame(depth: Dimensions.Screen.depth(self.physicalMetrics))
        HStack {
            DebugMainView()
                .frame(width: Dimensions.Screen.totalSize(self.physicalMetrics) * 1/2,
                       height: Dimensions.Screen.totalSize(self.physicalMetrics) * 1/2)
                .frame(depth: Dimensions.Screen.depth(self.physicalMetrics))
        }
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
