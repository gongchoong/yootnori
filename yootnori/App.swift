//
//  yootnoriApp.swift
//  yootnori
//
//  Created by David Lee on 9/21/24.
//

import SwiftUI

@main
struct yootnoriApp: App {
    @StateObject private var model = AppModel()
    var body: some Scene {
        WindowGroup {
            FullSpaceView()
                .environmentObject(model)
        }.windowStyle(.volumetric)

        ImmersiveSpace(id: "ImmersiveSpace") {
            FullSpaceView()
                .environmentObject(model)
        }
    }
}
