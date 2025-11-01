//
//  TileView.swift
//  yootnori
//
//  Created by David Lee on 9/21/24.
//

import SwiftUI

struct TileView: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.boardViewConstants) private var boardViewConstants

    private var tile: Tile
    private let didTapTile: ((Tile) -> Void)
    
    init(tile: Tile, didTapTile: @escaping ((Tile) -> Void)) {
        self.tile = tile
        self.didTapTile = didTapTile
    }
    
    var body: some View {
        GeometryReader { geometry in
            switch tile.type {
            case .edge, .inner:
                VertexTileView(
                    tile: tile,
                    tileWidth: geometry.size.width,
                    tileHeight: geometry.size.height
                )
            case .hidden, .stage:
                Color.clear
            }
        }
        .onTapGesture {
            didTapTile(tile)
        }
        .disabled(model.gameState == .animating)
    }
}

#Preview {
    TileView(
        tile: Tile(
            type: .edge,
            location: .topLeftCorner,
            paths: [
                .right,
                .bottom,
                .bottomRight
            ],
            nodeName: .empty
        ), didTapTile: {_ in }
    )
}
