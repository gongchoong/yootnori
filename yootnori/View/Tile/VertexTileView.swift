//
//  CornerTile.swift
//  yootnori
//
//  Created by David Lee on 9/22/24.
//

import SwiftUI

struct VertexTileView: View {
    enum Constants {
        static var verticeInnerHeightConstant: CGFloat = 0.35
        static var verticeOuterHeightConstant: CGFloat = 0.75
        static var verticeOuterLineWidth: CGFloat = 7
        static var edgeInnerHeightConstant: CGFloat = 0.3
        static var edgeOuterHeightConstant: CGFloat = 0.5
        static var edgeOuterLineWidth: CGFloat = 10
        static var innerTileConstant: CGFloat = 1.25
    }
    private let tile: Tile
    private let tileWidth: CGFloat
    private let tileHeight: CGFloat
    var body: some View {
        switch tile.location {
        case .topLeftCorner, .topRightCorner, .bottomLeftCorner, .bottomRightCorner, .center:
            let innerCircleWidth = tile.type == .edge ?
                tileHeight * Constants.verticeInnerHeightConstant :
                tileHeight * Constants.verticeInnerHeightConstant * Constants.innerTileConstant
            let outerCircleHeight = tile.type == .edge ?
                tileHeight * Constants.verticeOuterHeightConstant :
                tileHeight * Constants.verticeOuterHeightConstant * Constants.innerTileConstant
            Circle()
                .fill(.black)
                .frame(
                    width: innerCircleWidth,
                    height: innerCircleWidth
                )
            Circle()
                .fill(.clear)
                .stroke(.black, lineWidth: Constants.verticeOuterLineWidth)
                .frame(
                    width: outerCircleHeight,
                    height: outerCircleHeight
                )
            ForEach(tile.paths ?? [], id: \.self) { path in
                TilePathView(
                    tilePath: path,
                    tileWidth: tileWidth,
                    tileHeight: tileHeight,
                    innerCircleHeight: innerCircleWidth,
                    outerCircleHeight: outerCircleHeight
                )
            }
        case .edgeTop, .edgeBottom, .edgeRight, .edgeLeft, .diagonalTopLeft, .diagonalTopRight, .diagonalBottomLeft, .diagonalBottomRight:
            let innerCircleWidth = tile.type == .edge ?
                tileHeight * Constants.edgeInnerHeightConstant :
                tileHeight * Constants.edgeInnerHeightConstant * Constants.innerTileConstant
            let outerCircleHeight = tile.type == .edge ?
                tileHeight * Constants.edgeOuterHeightConstant :
                tileHeight * Constants.edgeOuterHeightConstant * Constants.innerTileConstant
            Circle()
                .fill(.black)
                .frame(
                    width: innerCircleWidth,
                    height: innerCircleWidth
                )
            Circle()
                .fill(.clear)
                .stroke(.black, lineWidth: Constants.edgeOuterLineWidth)
                .frame(
                    width: outerCircleHeight,
                    height: outerCircleHeight
                )
            ForEach(tile.paths ?? [], id: \.self) { path in
                TilePathView(
                    tilePath: path,
                    tileWidth: tileWidth,
                    tileHeight: tileHeight,
                    innerCircleHeight: innerCircleWidth,
                    outerCircleHeight: outerCircleHeight
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

#Preview {
    VertexTileView(
        tile: Tile(
            type: .edge,
            location: .topLeftCorner,
            paths: [
                .right,
                .bottom,
                .bottomRight
            ]
        ),
        tileWidth: 100,
        tileHeight: 100
    )
}
