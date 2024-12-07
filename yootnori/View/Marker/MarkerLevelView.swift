//
//  MarkerLevelView.swift
//  yootnori
//
//  Created by David Lee on 11/27/24.
//

import SwiftUI

struct MarkerLevelView: View {
    var tapAction: (() -> Void)
    var level: Int = 0

    var body: some View {
        Text("x\(level)")
            .gesture(TapGesture()
                .onEnded({
                    tapAction()
                }))
    }
}

#Preview {
    MarkerLevelView(tapAction: {})
}
