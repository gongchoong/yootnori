//
//  NodeMap.swift
//  yootnori
//
//  Created by David Lee on 11/5/24.
//

import Foundation
import RealityKit
import RealityKitContent

class NodeManager {
    private var nodeSet = Set<Node>()

    init() {
        generateNodeSet()
    }
}

extension NodeManager {
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

    func getNextNodes(from nodeName: NodeName) -> [NodeName] {
        return nodeSet.filter { $0.name == nodeName }.first?.next ?? []
    }

    func getNode(from nodeName: NodeName) -> Node? {
        return nodeSet.filter { $0.name == nodeName }.first
    }

    func getPreviousNodes(from nodeName: NodeName) -> [NodeName] {
        return nodeSet.filter { $0.name == nodeName }.first?.prev ?? []
    }
}
