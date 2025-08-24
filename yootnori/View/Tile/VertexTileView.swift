//
//  CornerTile.swift
//  yootnori
//
//  Created by David Lee on 9/22/24.
//

import SwiftUI

struct VertexTileView: View {
    @Environment(\.vertexTileViewConstants) private var vertexConstants
    @EnvironmentObject var model: AppModel

    private let tile: Tile
    private let tileWidth: CGFloat
    private let tileHeight: CGFloat
    var body: some View {
        switch tile.location {
        case .topLeftCorner, .topRightCorner, .bottomLeftCorner, .bottomRightCorner, .center:
            let innerCircleWidth = tile.type == .edge ?
                tileHeight * vertexConstants.verticeInnerHeightConstant :
                tileHeight * vertexConstants.verticeInnerHeightConstant * vertexConstants.innerTileConstant
            let outerCircleHeight = tile.type == .edge ?
                tileHeight * vertexConstants.verticeOuterHeightConstant :
                tileHeight * vertexConstants.verticeOuterHeightConstant * vertexConstants.innerTileConstant
            ZStack {
                VertexTileBackgroundView(
                    isHighlighted: model.shouldHighlight(for: tile),
                    circleHeight: tileHeight
                )
                TileDecorationView(
                    tile: tile,
                    tileWidth: tileWidth,
                    tileHeight: tileHeight,
                    innerCircleHeight: innerCircleWidth,
                    outerCircleHeight: outerCircleHeight,
                    lineWidth: vertexConstants.verticeOuterLineWidth
                )
            }

        case .edgeTop, .edgeBottom, .edgeRight, .edgeLeft, .diagonalTopLeft, .diagonalTopRight, .diagonalBottomLeft, .diagonalBottomRight:
            let innerCircleWidth = tile.type == .edge ?
                tileHeight * vertexConstants.edgeInnerHeightConstant :
                tileHeight * vertexConstants.edgeInnerHeightConstant * vertexConstants.innerTileConstant
            let outerCircleHeight = tile.type == .edge ?
                tileHeight * vertexConstants.edgeOuterHeightConstant :
                tileHeight * vertexConstants.edgeOuterHeightConstant * vertexConstants.innerTileConstant
            ZStack {
                VertexTileBackgroundView(
                    isHighlighted: model.shouldHighlight(for: tile),
                    circleHeight: tileHeight
                )
                TileDecorationView(
                    tile: tile,
                    tileWidth: tileWidth,
                    tileHeight: tileHeight,
                    innerCircleHeight: innerCircleWidth,
                    outerCircleHeight: outerCircleHeight,
                    lineWidth: vertexConstants.verticeOuterLineWidth
                )
            }
        default:
            EmptyView()
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
    let tile: Tile
    let tileWidth: CGFloat
    let tileHeight: CGFloat
    let innerCircleHeight: CGFloat
    let outerCircleHeight: CGFloat
    let lineWidth: CGFloat

    var body: some View {
        Group {
            Circle()
                .fill(.black)
                .frame(width: innerCircleHeight, height: innerCircleHeight)

            Circle()
                .fill(.clear)
                .stroke(.black, lineWidth: lineWidth)
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
