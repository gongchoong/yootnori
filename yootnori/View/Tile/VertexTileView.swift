//
//  CornerTile.swift
//  yootnori
//
//  Created by David Lee on 9/22/24.
//

import SwiftUI

struct VertexTileView: View {
    @EnvironmentObject var model: AppModel

    private let tile: Tile
    private let tileWidth: CGFloat
    private let tileHeight: CGFloat

    private var isHighlighted: Bool {
        model.targetNodes.contains { $0.name == tile.nodeName && !$0.isScoreable }
    }

    var body: some View {
        ZStack {
            VertexTileBackgroundView(
                tile: tile,
                isHighlighted: isHighlighted,
                circleHeight: tileHeight
            )
            TileDecorationView(
                tile: tile,
                tileWidth: tileWidth,
                tileHeight: tileHeight
            )
        }
    }
    
    init(
        tile: Tile,
        tileWidth: CGFloat,
        tileHeight: CGFloat
    ) {
        self.tile = tile
        self.tileWidth = tileWidth
        self.tileHeight = tileHeight
    }
}

struct TileDecorationView: View {
    @Environment(\.vertexTileViewConstants) private var vertexConstants
    @EnvironmentObject var model: AppModel

    private let tile: Tile
    private let tileWidth: CGFloat
    private let tileHeight: CGFloat

    private var innerCircleHeight: CGFloat {
        let height: CGFloat
        switch tile.location {
        case .topLeftCorner, .topRightCorner, .bottomLeftCorner, .bottomRightCorner, .center:
            height = tileHeight * vertexConstants.verticeInnerHeightConstant

        case .edgeTop, .edgeBottom, .edgeRight, .edgeLeft, .diagonalTopLeft, .diagonalTopRight, .diagonalBottomLeft, .diagonalBottomRight:
            height = tileHeight * vertexConstants.edgeInnerHeightConstant
        default:
            height = 0
        }
        return tile.type == .edge ? height : height * vertexConstants.innerTileConstant
    }

    private var outerCircleHeight: CGFloat {
        let height: CGFloat
        switch tile.location {
        case .topLeftCorner, .topRightCorner, .bottomLeftCorner, .bottomRightCorner, .center:
            height = tileHeight * vertexConstants.verticeOuterHeightConstant

        case .edgeTop, .edgeBottom, .edgeRight, .edgeLeft, .diagonalTopLeft, .diagonalTopRight, .diagonalBottomLeft, .diagonalBottomRight:
            height = tileHeight * vertexConstants.edgeOuterHeightConstant
        default:
            height = 0
        }
        return tile.type == .edge ? height : height * vertexConstants.innerTileConstant
    }

    init(tile: Tile, tileWidth: CGFloat, tileHeight: CGFloat, didTapScore: (() -> Void)? = nil) {
        self.tile = tile
        self.tileWidth = tileWidth
        self.tileHeight = tileHeight
    }

    var body: some View {
        ZStack {
            Group {
                Circle()
                    .fill(.black)
                    .frame(width: innerCircleHeight, height: innerCircleHeight)

                Circle()
                    .fill(.clear)
                    .stroke(.black, lineWidth: vertexConstants.verticeOuterLineWidth)
                    .frame(width: outerCircleHeight, height: outerCircleHeight)

                ForEach(tile.paths ?? [], id: \.self) { path in
                    TilePathView(
                        tilePath: path,
                        tileWidth: tileWidth,
                        tileHeight: tileHeight,
                        innerCircleHeight: innerCircleHeight,
                        outerCircleHeight: outerCircleHeight
                    )
                }
            }
        }
    }
}

#Preview {
    VertexTileView(
        tile: Tile(
            type: .edge,
            location: .topLeftCorner,
            paths: [
                .right,
                .bottom,
                .bottomRight
            ],
            nodeName: .empty
        ),
        tileWidth: 100,
        tileHeight: 100
    )
}
