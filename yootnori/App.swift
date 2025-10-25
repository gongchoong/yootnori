//
//  yootnoriApp.swift
//  yootnori
//
//  Created by David Lee on 9/21/24.
//

import SwiftUI
import RealityKitContent

@main
struct yootnoriApp: App {
    @StateObject private var model: AppModel

    init() {
        #if MOCK
        print("BUILD SETTING: MOCK")
        let sharePlayManager = SharePlayManagerMock()
        #else
        let sharePlayManager = SharePlayManager()
        #endif
        let appModel = AppModel(
            rollManager: YootRollManager(),
            gameStateManager: GameStateManager(),
            markerManager: MarkerManager(),
            gameEngine: GameEngine(),
            sharePlayManager: sharePlayManager
        )

        _model = StateObject(wrappedValue: appModel)

        RealityKitContent.MarkerComponent.registerComponent()
        MarkerRuntimeComponent.registerComponent()
        YootComponent.registerComponent()
    }

    var body: some Scene {
        WindowGroup {
            FullSpaceView()
                .environmentObject(model)
                .injectGameConstants()
        }.windowStyle(.volumetric)

        ImmersiveSpace(id: "ImmersiveSpace") {
            FullSpaceView()
                .environmentObject(model)
        }
    }
}
