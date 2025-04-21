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
    var boardAction: ((Action) -> Void)

    init(viewModel: BoardViewModel, action: @escaping ((Action) -> Void)) {
        self.boardViewModel = viewModel
        self.boardAction = action
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                ForEach(Array(boardViewModel.edgeTiles.enumerated()), id: \.offset) { rowIndex, row in
                    HStack(spacing: 0) {
                        ForEach(Array(row.enumerated()), id: \.offset) { columnIndex, tile in
                            let tileViewModel = TileViewModel(tile: tile, targetNodes: model.targetNodes)
                            TileView(tileViewModel: tileViewModel) { tile in
                                boardAction(.tapTile(tile))
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
                            let tileViewModel = TileViewModel(tile: tile, targetNodes: model.targetNodes)
                            TileView(tileViewModel: tileViewModel) { tile in
                                boardAction(.tapTile(tile))
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
    BoardView(viewModel: BoardViewModel(), action: {_ in })
}

