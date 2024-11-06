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
                .foregroundStyle(model.newMarkerSelected ? Color.accentColor : .white)
                .background(model.newMarkerSelected ? Color.white : Color.accentColor)
                .clipShape(Capsule())
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .animation(.easeInOut, value: model.newMarkerSelected)
                .disabled(!model.canPlayMarker)
            }
        }
    }
}

#Preview {
    DebugMainView()
}
