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
    let node: Node

    init(type: TileType, location: TileLocation?, paths: [TilePath]?, node: Node) {
        self.type = type
        self.location = location
        self.paths = paths
        self.node = node
    }
}
