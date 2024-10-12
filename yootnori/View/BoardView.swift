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
        HStack(spacing: 0) {
            ZStack {
                VStack(spacing: 0) {
                    ForEach(Array(Board.edgeTileLayout.enumerated()), id: \.offset) { rowIndex, row in
                        HStack(spacing: 0) {
                            ForEach(Array(row.enumerated()), id: \.offset) { columnIndex, _ in
                                // Outer blue tiles on the edges (first and last row/column)
                                let tile = Board.edgeTileLayout[rowIndex][columnIndex]
                                TileView(tile: tile, row: rowIndex, column: columnIndex)
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
                                let tile = Board.innerTileLayout[rowIndex][columnIndex]
                                TileView(tile: tile, row: rowIndex, column: columnIndex)
                            }
                        }
                    }
                }
                .frame(width: Dimensions.Screen.totalSize(self.physicalMetrics) * 4/6,
                       height: Dimensions.Screen.totalSize(self.physicalMetrics) * 4/6)
            }
            ZStack {
                VStack(spacing: 0) {
                    ForEach(0..<1) { row in
                        HStack(spacing: 0) {
                            ForEach(0..<6) { column in
                                // Outer blue tiles on the edges (first and last row/column)
                                let tile = Tile(type: .stage, position: nil, paths: nil)
                                TileView(tile: tile, row: row, column: column)
                            }
                        }
                    }
                }
                .frame(width: Dimensions.Screen.totalSize(self.physicalMetrics) * 1/6,
                       height: Dimensions.Screen.totalSize(self.physicalMetrics))
            }
        }
    }
}

#Preview {
    BoardView()
}

