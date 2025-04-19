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
                ForEach(Array(boardViewModel.edgeTiles.enumerated()), id: \.offset) { rowIndex, row in
                    HStack(spacing: 0) {
                        ForEach(Array(row.enumerated()), id: \.offset) { columnIndex, tile in
                            let tileViewModel = TileViewModel(tile: tile, targetNodes: model.targetNodes)
                            TileView(tileViewModel: tileViewModel) { nodeName in
                                let node = boardViewModel.getNode(name: nodeName)
                                model.perform(action: .tapTile(node))
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
                            TileView(tileViewModel: tileViewModel) { nodeName in
                                let node = boardViewModel.getNode(name: nodeName)
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

