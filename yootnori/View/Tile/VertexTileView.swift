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
    @EnvironmentObject var model: AppModel

    private let tile: Tile
    private let tileWidth: CGFloat
    private let tileHeight: CGFloat
    private let innerCircleHeight: CGFloat
    private let outerCircleHeight: CGFloat
    private let lineWidth: CGFloat

    init(tile: Tile, tileWidth: CGFloat, tileHeight: CGFloat, innerCircleHeight: CGFloat, outerCircleHeight: CGFloat, lineWidth: CGFloat, didTapScore: (() -> Void)? = nil) {
        self.tile = tile
        self.tileWidth = tileWidth
        self.tileHeight = tileHeight
        self.innerCircleHeight = innerCircleHeight
        self.outerCircleHeight = outerCircleHeight
        self.lineWidth = lineWidth
    }

    var body: some View {
        ZStack {
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
}

struct ScoreButton: View {
    @EnvironmentObject var model: AppModel
    var action: () -> Void   // closure for button tap

    var body: some View {
        Button(action: action) {
            ZStack {
                Rectangle()
                    .fill(Color.red)
                    .aspectRatio(2.8, contentMode: .fit)
                    .cornerRadius(6) // optional nicer look

                Text("SCORE")
                    .foregroundColor(.white)
                    .font(.largeTitle)
                    .bold()
            }
        }
        .frame(width: 140, height: 60)
        .buttonStyle(.plain) // prevents SwiftUI's default blue highlight
        .opacity(model.markerCanScore ? 1 : 0)
        .disabled(!model.markerCanScore)
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
