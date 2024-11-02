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
    private let index: Index
    @State private var taken: Bool = false
    
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
            print(index)
            Task { @MainActor in
                if !taken {
                    do {
                        try await model.perform(index: index)
                        taken = true
                    } catch {
                        //
                        print(error.localizedDescription)
                        taken = false
                    }
                }
            }
        }
    }
    
    init(tile: Tile, index: Index) {
        self.tile = tile
        self.index = index
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
            ]
        ),
        index: Index.inner(column: 0, row: 0)
    )
}
