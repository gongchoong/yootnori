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

extension EnvironmentValues {
    var vertexTileViewConstants: VertexTileViewConstants {
        get { self[VertexTileViewConstantsKey.self] }
        set { self[VertexTileViewConstantsKey.self] = newValue }
    }
}

struct InjectGameConstants: ViewModifier {
    let vertex: VertexTileViewConstants

    func body(content: Content) -> some View {
        content
            .environment(\.vertexTileViewConstants, vertex)
    }
}

extension View {
    func injectGameConstants(
        vertexTileViewConstants: VertexTileViewConstants = VertexTileViewConstants()
    ) -> some View {
        self.modifier(InjectGameConstants(
            vertex: vertexTileViewConstants
        ))
    }
}
