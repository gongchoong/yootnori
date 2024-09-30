//
//  FullSpaceView.swift
//  yootnori
//
//  Created by David Lee on 9/21/24.
//

import SwiftUI

struct FullSpaceView: View {
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    @EnvironmentObject var model: AppModel
    var body: some View {
        VStack(spacing: 12) {
            GameView()
                .environmentObject(model)
        }
        .offset(z: 500)
    }
}

#Preview {
    FullSpaceView()
}
