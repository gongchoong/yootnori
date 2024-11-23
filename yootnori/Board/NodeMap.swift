//
//  NodeMap.swift
//  yootnori
//
//  Created by David Lee on 11/5/24.
//

import Foundation
import RealityKit
import RealityKitContent

class NodeMap {
    private var nodeSet = Set<Node>()
    private var markerMap: [Node: Entity] = [:]

    init() {
        generateNodeSet()
        initializeMarkerMap()
    }
}

// MARK: Node Set
extension NodeMap {
    private func generateNodeSet() {
        nodeSet = [
            // Outer nodes
            .topLeftVertex, .bottomLeftVertex, .topRightVertex, .bottomRightVertex,
            .topNode1, .topNode2, .topNode3, .topNode4,
            .leftNode1, .leftNode2, .leftNode3, .leftNode4,
            .rightNode1, .rightNode2, .rightNode3, .rightNode4,
            .bottomNode1, .bottomNode2, .bottomNode3, .bottomNode4,

            // Inner nodes
            .leftTopDiagonal1, .leftTopDiagonal2,
            .rightTopDiagonal1, .rightTopDiagonal2,
            .center,
            .leftBottomDiagonal1, .leftBottomDiagonal2,
            .rightBottomDiagonal1, .rightBottomDiagonal2
        ]
    }

    func getNext(from nodeName: NodeName) -> [NodeName] {
        return nodeSet.filter { $0.name == nodeName }.first?.next ?? []
    }

    func getNode(from nodeName: NodeName) -> Node? {
        return nodeSet.filter { $0.name == nodeName }.first
    }

    func getPrevious(from nodeName: NodeName) -> [NodeName] {
        return nodeSet.filter { $0.name == nodeName }.first?.prev ?? []
    }
}

// MARK: Marker Map
extension NodeMap {
    private func initializeMarkerMap() {
        for (rowIndex, row) in Board.innerTileLayout.enumerated() {
            for (columnIndex, _) in row.enumerated() {
                let innerTile = Board.innerTileLayout[rowIndex][columnIndex]
                guard let node = getNode(from: innerTile.nodeName) else { return }
                setEmpty(node: node)
            }
        }

        for (rowIndex, row) in Board.edgeTileLayout.enumerated() {
            for (columnIndex, _) in row.enumerated() {
                // Outer blue tiles on the edges (first and last row/column)
                let edgeTile = Board.edgeTileLayout[rowIndex][columnIndex]
                guard let node = getNode(from: edgeTile.nodeName) else { return }
                setEmpty(node: node)
            }
        }
    }

    func setEmpty(node: Node) {
        markerMap[node] = .empty
    }

    func update(marker: Entity, node: Node) {
        markerMap[node] = marker
    }

    func getNode(from entity: Entity) -> Node? {
        return markerMap.first(where: {
            $0.value == entity
        })?.key
    }
}
