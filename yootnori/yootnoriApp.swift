//
//  yootnoriApp.swift
//  yootnori
//
//  Created by David Lee on 9/21/24.
//

import SwiftUI

@main
struct yootnoriApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }.windowStyle(.volumetric)

        ImmersiveSpace(id: "ImmersiveSpace") {
            ImmersiveView()
        }.immersionStyle(selection: .constant(.full), in: .full)
    }
}
