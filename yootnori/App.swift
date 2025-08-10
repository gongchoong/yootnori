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
    @StateObject private var gameStateManager: GameStateManager

    init() {
        let _gameSatemanager = GameStateManager()
        let appModel = AppModel(
            rollViewModel: ThrowViewModel(),
            playerTurnViewModel: PlayerTurnViewModel(),
            gameStateManager: _gameSatemanager
        )

        _model = StateObject(wrappedValue: appModel)
        _gameStateManager = StateObject(wrappedValue: _gameSatemanager)

        RealityKitContent.MarkerComponent.registerComponent()
        MarkerRuntimeComponent.registerComponent()
        YootComponent.registerComponent()
    }

    var body: some Scene {
        WindowGroup {
            FullSpaceView()
                .environmentObject(model)
                .environmentObject(gameStateManager)
        }.windowStyle(.volumetric)

        ImmersiveSpace(id: "ImmersiveSpace") {
            FullSpaceView()
                .environmentObject(model)
                .environmentObject(gameStateManager)
        }
    }
}
