//
//  Tile.swift
//  yootnori
//
//  Created by David Lee on 9/29/24.
//

import Foundation

struct Tile {
    let type: TileType
    let position: TilePosition?
    let paths: [TilePath]?
    
    init(type: TileType, position: TilePosition?, paths: [TilePath]?) {
        self.type = type
        self.position = position
        self.paths = paths
    }
}
