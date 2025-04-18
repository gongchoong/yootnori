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
    let node: Node
    
    init(tile: Tile, node: Node, targetNodes: Set<TargetNode>) {
        self.tile = tile
        self.node = node
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
        node.name != .empty
    }

    var isDestinationNode: Bool {
        targetNodes.contains { $0.name == node.name }
    }
}


