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
    var didTapTile: ((Tile) -> Void)

    init(viewModel: BoardViewModel, _ action: @escaping ((Tile) -> Void)) {
        self.boardViewModel = viewModel
        self.didTapTile = action
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                ForEach(Array(boardViewModel.edgeTiles.enumerated()), id: \.offset) { rowIndex, row in
                    HStack(spacing: 0) {
                        ForEach(Array(row.enumerated()), id: \.offset) { columnIndex, tile in
                            TileView(tile: tile) { tile in
                                didTapTile(tile)
                            }
                        }
                    }
                }
            }
            .frame(width: Dimensions.Screen.totalSize(self.physicalMetrics),
                   height: Dimensions.Screen.totalSize(self.physicalMetrics))

            VStack(spacing: 0) {
                ForEach(Array(boardViewModel.innerTiles.enumerated()), id: \.offset) { rowIndex, row in
                    HStack(spacing: 0) {
                        ForEach(Array(row.enumerated()), id: \.offset) { columnIndex, tile in
                            TileView(tile: tile) { tile in
                                didTapTile(tile)
                            }
                        }
                    }
                }
            }
            .frame(width: Dimensions.Screen.totalSize(self.physicalMetrics) * 4/6,
                   height: Dimensions.Screen.totalSize(self.physicalMetrics) * 4/6)
        }
        .glassBackgroundEffect()
    }
}


#Preview {
    BoardView(viewModel: BoardViewModel(), {_ in })
}

