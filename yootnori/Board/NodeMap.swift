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
    private var markerMap: [Node: Entity?] = [:]

    init() {
        generateNodeSet()
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
    func create(marker: Entity, node: Node) {
        markerMap[node] = marker
    }

    func remove(node: Node) {
        markerMap[node] = nil
    }

    func update(marker: Entity, node: Node) {
        guard let previousNode = markerMap.first(where: { $0.value == marker })?.key else { return }
        markerMap[previousNode] = nil
        markerMap[node] = marker
    }

    func getNode(from entity: Entity) -> Node? {
        return markerMap.first(where: {
            $0.value == entity
        })?.key
    }

    func printMap() {
        let map = markerMap.filter { $0.value != nil }
        for item in map.keys {
            print(item.name)
        }
    }
}
