//
//  DebugMainView.swift
//  yootnori
//
//  Created by David Lee on 10/20/24.
//

import SwiftUI

struct DebugMainView: View {
    @EnvironmentObject var model: AppModel
    var rollButtonTapped: ((Yoot) -> Void)
    var markerButtonTapped: (() -> Void)

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.blue)
            VStack(spacing: 10) {
                ForEach(Yoot.allCases, id: \.self) { roll in
                    Button {
                        rollButtonTapped(roll)
                    } label: {
                        Text("Roll \(roll.steps)")
                            .font(.system(size: 40))
                            .fontWeight(.bold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .disabled(model.hasRemainingRoll || model.isLoading)

                Text(String(describing: model.yootRollSteps))
                    .font(.system(size: 40))
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)

                Button {
                    markerButtonTapped()
                } label: {
                    Text("\(model.markersToGo)x")
                        .font(.system(size: 40))
                }
                .foregroundStyle(model.selectedMarker == .new ? Color.accentColor : .white)
                .background(model.selectedMarker == .new ? Color.white : Color.accentColor)
                .clipShape(Capsule())
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .animation(.easeInOut, value: model.selectedMarker == .new)
                .disabled(!model.hasRemainingRoll || model.isLoading)
            }
        }
    }
}

#Preview {
    DebugMainView(rollButtonTapped: {_ in }, markerButtonTapped: {})
}
