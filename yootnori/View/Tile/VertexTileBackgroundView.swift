//
//  VertexTileHighlightView.swift
//  yootnori
//
//  Created by David Lee on 8/24/25.
//

import SwiftUI

struct VertexTileBackgroundView: View {
    @Environment(\.vertexTileViewConstants) private var vertexConstants
    @Environment(\.boardViewConstants) private var boardViewConstants

    private let isHighlighted: Bool
    private let circleHeight: CGFloat

    init(isHighlighted: Bool, circleHeight: CGFloat) {
        self.isHighlighted = isHighlighted
        self.circleHeight = circleHeight
    }

    var body: some View {
        ZStack {
            Rectangle()
                .fill(boardViewConstants.boardColor)
            Circle()
                .fill(.white)
                .frame(width: circleHeight, height: circleHeight)
                .opacity(isHighlighted ? 1 : 0)
        }
    }
}
