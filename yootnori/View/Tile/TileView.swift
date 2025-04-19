//
//  TileView.swift
//  yootnori
//
//  Created by David Lee on 9/21/24.
//

import SwiftUI

struct TileView: View {
    @EnvironmentObject var model: AppModel
    private var viewModel: TileViewModel
    private let didTapTile: ((NodeName) -> Void)
    
    init(tileViewModel: TileViewModel, didTapTile: @escaping ((NodeName) -> Void)) {
        self.viewModel = tileViewModel
        self.didTapTile = didTapTile
    }
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            ZStack {
                switch viewModel.tileType {
                case .edge:
                    Rectangle()
                        .fill(viewModel.isMarkerPlaceable ? .white : .blue)
                case .hidden:
                    Rectangle()
                        .fill(.blue)
                case .inner:
                    Rectangle()
                        .fill(viewModel.isMarkerPlaceable ? .white : .blue)
                        .border(.black, width: 1)
                case .stage:
                    Rectangle()
                        .fill(.blue)
                }
                if viewModel.isEdgeOrInnerTile {
                    ZStack {
                        VertexTileView(
                            tile: viewModel.tile,
                            tileWidth: width,
                            tileHeight: height
                        )
                    }
                }
            }
        }
        .onTapGesture {
            if viewModel.isMarkerPlaceable {
                didTapTile(viewModel.tile.nodeName)
            }
        }
        .disabled(model.isLoading)
    }
}

#Preview {
    TileView(
        tileViewModel: TileViewModel(tile: Tile(
            type: .edge,
            location: .topLeftCorner,
            paths: [
                .right,
                .bottom,
                .bottomRight
            ],
            nodeName: .empty
        ), targetNodes: Set<TargetNode>()), didTapTile: {_ in }
    )
}
