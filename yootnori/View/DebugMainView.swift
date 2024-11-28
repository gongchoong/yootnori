//
//  DebugMainView.swift
//  yootnori
//
//  Created by David Lee on 10/20/24.
//

import SwiftUI

struct DebugMainView: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.blue)
            VStack(spacing: 10) {
                Button {
                    Task { @MainActor in
                        await model.pressedRollButton()
                    }
                } label: {
                    Text("Roll!")
                        .font(.system(size: 40))
                        .fontWeight(.bold)
                    
                }
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .disabled(model.hasRemainingRoll || model.isLoading)

                Text(String(describing: model.yootRollSteps))
                    .font(.system(size: 40))
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)

                Button {
                    model.pressedNewMarkerButton()
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
    DebugMainView()
}
