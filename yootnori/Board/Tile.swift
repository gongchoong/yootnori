//
//  Tile.swift
//  yootnori
//
//  Created by David Lee on 9/29/24.
//

import Foundation

struct Tile {
    let type: TileType
    let location: TileLocation?
    let paths: [TilePath]?
    let nodeDetails: NodeDetails

    init(type: TileType, location: TileLocation?, paths: [TilePath]?, nodeDetails: NodeDetails) {
        self.type = type
        self.location = location
        self.paths = paths
        self.nodeDetails = nodeDetails
    }
}
