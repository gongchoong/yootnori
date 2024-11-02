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
    
    init(type: TileType, location: TileLocation?, paths: [TilePath]?) {
        self.type = type
        self.location = location
        self.paths = paths
    }
}
