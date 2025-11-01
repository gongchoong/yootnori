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

    private let tile: Tile
    private let isHighlighted: Bool
    private let circleHeight: CGFloat

    let cornerRadius: CGFloat = 35

    private var topLeading: CGFloat {
        return tile.location == .topLeftCorner ? cornerRadius : 0
    }

    private var topTrailing: CGFloat {
        return tile.location == .topRightCorner ? cornerRadius : 0
    }

    private var bottomLeading: CGFloat {
        return tile.location == .bottomLeftCorner ? cornerRadius : 0
    }

    private var bottomTrailing: CGFloat {
        return tile.location == .bottomRightCorner ? cornerRadius : 0
    }

    init(tile: Tile, isHighlighted: Bool, circleHeight: CGFloat) {
        self.tile = tile
        self.isHighlighted = isHighlighted
        self.circleHeight = circleHeight
    }

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color(.systemBackground))
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: topLeading,
                        bottomLeadingRadius: bottomLeading,
                        bottomTrailingRadius: bottomTrailing,
                        topTrailingRadius: topTrailing
                    )
                )
            Circle()
                .fill(.white)
                .frame(width: circleHeight, height: circleHeight)
                .opacity(isHighlighted ? 1 : 0)
        }
    }
}
