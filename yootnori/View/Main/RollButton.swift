//
//  RollButton.swift
//  yootnori
//
//  Created by David Lee on 6/22/25.
//

import SwiftUI

struct RollButton: View {
    @ObservedObject var throwViewModel: ThrowViewModel

    init(throwViewModel: ThrowViewModel) {
        self.throwViewModel = throwViewModel
    }

    var body: some View {
        Button(action: {
            throwViewModel.roll()
        }) {
            Text("ROLL")
                .font(.system(size: 50, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(width: 200, height: 80)
                .background(
                    RoundedRectangle(cornerRadius: 40)
                        .fill(Color.red.opacity(0.8))
                        .padding(.horizontal, -18)
                )
        }
        .hoverEffect(.lift)
        .opacity(throwViewModel.started ? 0 : 1)
    }
}
