//
//  TileViewModel.swift
//  yootnori
//
//  Created by David Lee on 4/17/25.
//

import SwiftUI

class TileViewModel: ObservableObject {
    @Published var targetNodes = Set<TargetNode>()
    let tile: Tile
    
    init(tile: Tile, targetNodes: Set<TargetNode>) {
        self.tile = tile
        self.targetNodes = targetNodes
    }
    
    var tileType: TileType {
        tile.type
    }
    
    var isEdgeOrInnerTile: Bool {
        tileType == .edge || tileType == .inner
    }
    
    var isMarkerPlaceable: Bool {
        isVisibleTile && isDestinationNode
    }

    var isVisibleTile: Bool {
        tile.nodeName != .empty
    }

    var isDestinationNode: Bool {
        targetNodes.contains { $0.name == tile.nodeName }
    }
}


