//
//  MarkerMap.swift
//  yootnori
//
//  Created by David Lee on 11/10/24.
//

import Foundation
import RealityKit
import RealityKitContent

class MarkerMap {
    private var map: [Node: Entity] = [:]

    init() {
    }
}

extension MarkerMap {
    func initializeOuterNodes(nodeMap: NodeMap) {
        for (rowIndex, row) in Board.edgeTileLayout.enumerated() {
            for (columnIndex, _) in row.enumerated() {
                // Outer blue tiles on the edges (first and last row/column)
                let edgeTile = Board.edgeTileLayout[rowIndex][columnIndex]
                guard let node = nodeMap.getNode(from: edgeTile.nodeName) else { return }
                map[node] = .empty
            }
        }
    }

    func initializeInnerNodes(nodeMap: NodeMap) {
        for (rowIndex, row) in Board.innerTileLayout.enumerated() {
            for (columnIndex, _) in row.enumerated() {
                let innerTile = Board.innerTileLayout[rowIndex][columnIndex]
                print(innerTile.nodeName)
                guard let node = nodeMap.getNode(from: innerTile.nodeName) else { return }
                map[node] = .empty
            }
        }
    }
}

extension MarkerMap {
    func update(node: Node, entity: Entity = .empty) {
        map[node] = entity
    }

    func getNode(from entity: Entity) -> Node? {
        return map.first(where: {
            guard let valueComponent = $0.value.components[MarkerComponent.self] else {
                return false
            }
            let entityComponent: MarkerComponent = entity.components[MarkerComponent.self]!
            return valueComponent.nodeName == entityComponent.nodeName
        })?.key
    }
}
