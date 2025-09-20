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

extension EnvironmentValues {
    var vertexTileViewConstants: VertexTileViewConstants {
        get { self[VertexTileViewConstantsKey.self] }
        set { self[VertexTileViewConstantsKey.self] = newValue }
    }

    var boardViewConstants: BoardViewConstants {
        get { self[BoardViewConstantsKey.self] }
        set { self[BoardViewConstantsKey.self] = newValue }
    }
}

struct InjectGameConstants: ViewModifier {
    let vertex: VertexTileViewConstants
    let board: BoardViewConstants

    func body(content: Content) -> some View {
        content
            .environment(\.vertexTileViewConstants, vertex)
            .environment(\.boardViewConstants, board)
    }
}

extension View {
    func injectGameConstants(
        vertexTileViewConstants: VertexTileViewConstants = VertexTileViewConstants(),
        boardViewConstants: BoardViewConstants = BoardViewConstants()
    ) -> some View {
        self.modifier(InjectGameConstants(
            vertex: vertexTileViewConstants,
            board: boardViewConstants
        ))
    }
}
