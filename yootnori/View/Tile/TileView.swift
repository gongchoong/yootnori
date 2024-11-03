//
//  TileView.swift
//  yootnori
//
//  Created by David Lee on 9/21/24.
//

import SwiftUI

struct TileView: View {
    @EnvironmentObject var model: AppModel
    private let tile: Tile
    private let node: Node
    
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
                        .fill(.blue)
                case .inner:
                    Rectangle()
                        .fill(.blue)
                        .border(.black, width: 1)
                case .stage:
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
        .onTapGesture {
            if canPlaceMarker {
                print(node)
                model.perform(node: node)
            }
        }
    }
    
    init(tile: Tile, node: Node) {
        self.tile = tile
        self.node = node
    }
}

extension TileView {
    var canPlaceMarker: Bool {
        isVisibleTile && !containsMarker
    }

    var isVisibleTile: Bool {
        node.details.name != .empty
    }

    var containsMarker: Bool {
        model.hasMarker(on: node)
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
            nodeDetails: .empty
        ),
        node: Node(details: .empty, index: .outer(column: 0, row: 0))
    )
}
