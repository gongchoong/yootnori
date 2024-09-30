//
//  TileView.swift
//  yootnori
//
//  Created by David Lee on 9/21/24.
//

import SwiftUI

struct TileView: View {
    private let tile: Tile
    private let row: Int
    private let column: Int
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            ZStack {
                switch tile.type {
                case .edge:
                    Rectangle()
                        .fill(.blue)
                case .hidden:
                    Rectangle()
                        .fill(.clear)
                case .inner:
                    Rectangle()
                        .fill(.blue)
                }
                if tile.type == .edge || tile.type == .inner {
                    ZStack {
                        VertexTileView(
                            tile: tile,
                            tileWidth: width,
                            tileHeight: height
                        )
                    }
                }
            }
        }
    }
    
    init(tile: Tile, row: Int, column: Int) {
        self.tile = tile
        self.row = row
        self.column = column
    }
}

#Preview {
    TileView(
        tile: Tile(
            type: .edge,
            position: .topLeftCorner,
            paths: [
                .right,
                .bottom,
                .bottomRight
            ]
        ),
        row: 0,
        column: 0
    )
}
