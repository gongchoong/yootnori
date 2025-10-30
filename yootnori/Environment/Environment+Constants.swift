//
//  Environment+Constants.swift
//  yootnori
//
//  Created by David Lee on 8/24/25.
//

import SwiftUI

// Environment+LayoutConstants.swift
private struct VertexTileViewConstantsKey: EnvironmentKey {
    static let defaultValue = VertexTileViewConstants()
}

private struct BoardViewConstantsKey: EnvironmentKey {
    static let defaultValue = BoardViewConstants()
}

private struct MainViewConstantsKey: EnvironmentKey {
    static let defaultValue = MainViewConstants()
}

extension EnvironmentValues {
    var vertexTileViewConstants: VertexTileViewConstants {
        get { self[VertexTileViewConstantsKey.self] }
        set { self[VertexTileViewConstantsKey.self] = newValue }
    }

    var boardViewConstants: BoardViewConstants {
        get { self[BoardViewConstantsKey.self] }
        set { self[BoardViewConstantsKey.self] = newValue }
    }

    var mainViewConstants: MainViewConstants {
        get { self[MainViewConstantsKey.self] }
        set { self[MainViewConstantsKey.self] = newValue }
    }
}

struct InjectGameConstants: ViewModifier {
    let vertex: VertexTileViewConstants
    let board: BoardViewConstants
    let main: MainViewConstants

    func body(content: Content) -> some View {
        content
            .environment(\.vertexTileViewConstants, vertex)
            .environment(\.boardViewConstants, board)
            .environment(\.mainViewConstants, main)
    }
}

extension View {
    func injectGameConstants(
        vertexTileViewConstants: VertexTileViewConstants = VertexTileViewConstants(),
        boardViewConstants: BoardViewConstants = BoardViewConstants(),
        mainViewConstants: MainViewConstants = MainViewConstants()
    ) -> some View {
        self.modifier(InjectGameConstants(
            vertex: vertexTileViewConstants,
            board: boardViewConstants,
            main: mainViewConstants
        ))
    }
}
