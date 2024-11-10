//
//  BoardView.swift
//  yootnori
//
//  Created by David Lee on 9/21/24.
//

import SwiftUI

struct BoardView: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.physicalMetrics) var physicalMetrics
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                ForEach(Array(Board.edgeTileLayout.enumerated()), id: \.offset) { rowIndex, row in
                    HStack(spacing: 0) {
                        ForEach(Array(row.enumerated()), id: \.offset) { columnIndex, _ in
                            // Outer blue tiles on the edges (first and last row/column)
                            let edgeTile = Board.edgeTileLayout[rowIndex][columnIndex]
                            let node = Node(
                                name: edgeTile.nodeName,
                                index: .outer(
                                    column: columnIndex,
                                    row: rowIndex
                                )
                            )
                            TileView(tile: edgeTile, node: node)
                        }
                    }
                }
            }
            .frame(width: Dimensions.Screen.totalSize(self.physicalMetrics),
                   height: Dimensions.Screen.totalSize(self.physicalMetrics))

            VStack(spacing: 0) {
                ForEach(Array(Board.innerTileLayout.enumerated()), id: \.offset) { rowIndex, row in
                    HStack(spacing: 0) {
                        ForEach(Array(row.enumerated()), id: \.offset) { columnIndex, _ in
                            let innerTile = Board.innerTileLayout[rowIndex][columnIndex]
                            let node = Node(
                                name: innerTile.nodeName,
                                index: .inner(
                                    column: columnIndex,
                                    row: rowIndex
                                )
                            )
                            TileView(tile: innerTile, node: node)
                        }
                    }
                }
            }
            .frame(width: Dimensions.Screen.totalSize(self.physicalMetrics) * 4/6,
                   height: Dimensions.Screen.totalSize(self.physicalMetrics) * 4/6)
        }
    }
}

#Preview {
    BoardView()
}

