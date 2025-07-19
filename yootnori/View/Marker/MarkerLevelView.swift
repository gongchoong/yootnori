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
    var team: Team = .black

    var body: some View {
        Text("x\(level)")
            .font(.title)
            .foregroundStyle(team.color)
            .bold()
            .gesture(TapGesture()
                .onEnded({
                    tapAction()
                }))
    }
}

#Preview {
    MarkerLevelView(tapAction: {})
}
