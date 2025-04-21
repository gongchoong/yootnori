//
//  BoardViewModel.swift
//  yootnori
//
//  Created by David Lee on 4/17/25.
//

import Foundation
import RealityKit

class BoardViewModel: ObservableObject {
    private(set) var edgeTiles: [[Tile]] = []
    private(set) var innerTiles: [[Tile]] = []
    
    init() {
        generateTiles()
    }
    
    private func generateTiles() {
        edgeTiles = TileConfig.edgeTileLayoutNames.map { row in
            row.map { name in
                guard
                    let type = TileConfig.tileTypeMap[name],
                    let location = TileConfig.tileLocationMap[name],
                    let paths = TileConfig.tilePathMap[name]
                else {
                    return Tile(type: .hidden, location: nil, paths: nil, nodeName: .empty)
                }

                return Tile(type: type, location: location, paths: paths, nodeName: name)
            }
        }

        innerTiles = TileConfig.innerTileLayoutNames.map { row in
            row.map { name in
                guard
                    let type = TileConfig.tileTypeMap[name],
                    let location = TileConfig.tileLocationMap[name],
                    let paths = TileConfig.tilePathMap[name]
                else {
                    return Tile(type: .hidden, location: nil, paths: nil, nodeName: .empty)
                }

                return Tile(type: type, location: location, paths: paths, nodeName: name)
            }
        }
    }

}
