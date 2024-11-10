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
                        .fill(isMarkerPlaceable ? .white : .blue)
                case .hidden:
                    Rectangle()
                        .fill(.blue)
                case .inner:
                    Rectangle()
                        .fill(isMarkerPlaceable ? .white : .blue)
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
            if isMarkerPlaceable {
                model.perform(action: .tapTile(node))
            }
        }
    }
    
    init(tile: Tile, node: Node) {
        self.tile = tile
        self.node = node
    }
}

extension TileView {
    var isMarkerPlaceable: Bool {
        isVisibleTile && isDestinationNode
    }

    var isVisibleTile: Bool {
        node.name != .empty
    }

    var isDestinationNode: Bool {
        model.targetNodes.contains { $0.name == node.name }
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
        ),
        node: Node(name: .empty, index: .outer(column: 0, row: 0))
    )
}
