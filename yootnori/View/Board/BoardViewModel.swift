//
//  BoardViewModel.swift
//  yootnori
//
//  Created by David Lee on 4/17/25.
//

import Foundation
import RealityKit

class BoardViewModel: ObservableObject {
    private var rootEntity: Entity
    private var nodes = Set<Node>()
    var edgeTiles: [[Tile]] = []
    var innerTiles: [[Tile]] = []
    
    init(rootEntity: Entity) {
        self.rootEntity = rootEntity
        generateTiles()
        generateNodes()
    }
    
    private func generateNodes() {
        for name in BoardConfig.nodeNames {
            guard let index = BoardConfig.nodeIndexMap[name], let relationships = BoardConfig.nodeRelationships[name] else {
                continue
            }
            
            let node = Node(name: name, index: index, next: relationships.next, prev: relationships.prev)
            nodes.insert(node)
        }
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

extension BoardViewModel {
    func getNode(name: NodeName) -> Node {
        guard let node = nodes.filter({ $0.name == name }).first else {
            return Node(name: .empty, index: .inner(column: 0, row: 0), next: [], prev: [])
        }
        return node
    }
}
