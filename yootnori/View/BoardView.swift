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
    @ObservedObject var boardViewModel: BoardViewModel
    
    init(viewModel: BoardViewModel) {
        self.boardViewModel = viewModel
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                ForEach(Array(Board.edgeTileLayout.enumerated()), id: \.offset) { rowIndex, row in
                    HStack(spacing: 0) {
                        ForEach(Array(row.enumerated()), id: \.offset) { columnIndex, _ in
                            // Outer blue tiles on the edges (first and last row/column)
                            let tile = Board.edgeTileLayout[rowIndex][columnIndex]
                            let node = boardViewModel.getNode(from: tile) ?? .empty
                            let tileViewModel = TileViewModel(tile: tile, node: node, targetNodes: model.targetNodes)
                            TileView(tileViewModel: tileViewModel) { node in
                                model.perform(action: .tapTile(node))
                            }
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
                            let node = boardViewModel.getNode(from: tile) ?? .empty
                            let tileViewModel = TileViewModel(tile: tile, node: node, targetNodes: model.targetNodes)
                            TileView(tileViewModel: tileViewModel) { node in
                                model.perform(action: .tapTile(node))
                            }
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
    BoardView(viewModel: BoardViewModel(rootEntity: .empty))
}

