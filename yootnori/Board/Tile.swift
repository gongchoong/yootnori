//
//  Tile.swift
//  yootnori
//
//  Created by David Lee on 9/29/24.
//

import Foundation

struct Tile: Hashable {
    let type: TileType
    let location: TileLocation?
    let paths: [TilePath]?
    let nodeName: NodeName

    init(type: TileType, location: TileLocation?, paths: [TilePath]?, nodeName: NodeName) {
        self.type = type
        self.location = location
        self.paths = paths
        self.nodeName = nodeName
    }
    
    // Conforming to Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(type)
        hasher.combine(location)
        hasher.combine(paths)
        hasher.combine(nodeName)
    }
    
    static func == (lhs: Tile, rhs: Tile) -> Bool {
        lhs.type == rhs.type && lhs.location == rhs.location && lhs.paths == rhs.paths && lhs.nodeName == rhs.nodeName
    }
    
    var isEdgeTile: Bool {
        type == .edge
    }
    
    var isInnerTile: Bool {
        type == .inner
    }
}
