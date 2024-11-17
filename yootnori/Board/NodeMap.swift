//
//  NodeMap.swift
//  yootnori
//
//  Created by David Lee on 11/5/24.
//

import Foundation

class NodeMap {
    private var map = Set<Node>()

    init() {
        generateNodeMap()
    }
}

private extension NodeMap {
    func generateNodeMap() {
        map = [
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
}

extension NodeMap {
    func getNext(name: NodeName) -> [NodeName] {
        return map.filter { $0.name == name }.first?.next ?? []
    }

    func getNode(from nodeName: NodeName) -> Node? {
        return map.filter { $0.name == nodeName }.first
    }

    func getPrevious(name: NodeName) -> [NodeName] {
        return map.filter { $0.name == name }.first?.prev ?? []
    }
}
