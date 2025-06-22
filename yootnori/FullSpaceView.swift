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
        MainView()
            .frame(
                width: Dimensions.Screen.totalSize(self.physicalMetrics),
                height: Dimensions.Screen.totalSize(self.physicalMetrics)
            )
            .frame(depth: Dimensions.Screen.depth(self.physicalMetrics))
            .environmentObject(model)
    }
}

#Preview {
    FullSpaceView()
}
