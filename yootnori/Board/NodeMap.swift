//
//  NodeMap.swift
//  yootnori
//
//  Created by David Lee on 11/5/24.
//

import Foundation

class NodeMap {
    private var map = Set<NodeDetails>()

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
    
    func getNodeDetail(from node: Node) -> NodeDetails? {
        return map.filter { $0.name == node.name }.first
    }
}

struct NodeDetails: Hashable {
    let name: NodeName
    let next: [NodeName]
    let prev: [NodeName]
}

// MARK: Outer nodes
extension NodeDetails {
    // MARK: Vertices
    static var topLeftVertex: Self {
        NodeDetails(
            name: .topLeftVertex,
            next: [.leftNode1, .leftTopDiagonal1],
            prev: [.topNode4]
        )
    }

    static var bottomLeftVertex: Self {
        NodeDetails(
            name: .bottomLeftVertex,
            next: [.bottomNode1],
            prev: [.leftNode4, .leftBottomDiagonal2]
        )
    }

    static var topRightVertex: Self {
        NodeDetails(
            name: .topRightVertex,
            next: [.topNode1, .rightTopDiagonal1],
            prev: [.rightNode4]
        )
    }

    static var bottomRightVertex: Self {
        NodeDetails(
            name: .bottomRightVertex,
            next: [.rightNode1],
            prev: [.bottomNode4, .rightBottomDiagonal2]
        )
    }

    // MARK: Top nodes
    static var topNode1: Self {
        NodeDetails(
            name: .topNode1,
            next: [.topNode2],
            prev: [.topRightVertex]
        )
    }

    static var topNode2: Self {
        NodeDetails(
            name: .topNode2,
            next: [.topNode3],
            prev: [.topNode1]
        )
    }

    static var topNode3: Self {
        NodeDetails(
            name: .topNode3,
            next: [.topNode4],
            prev: [.topNode2]
        )
    }

    static var topNode4: Self {
        NodeDetails(
            name: .topNode4,
            next: [.topLeftVertex],
            prev: [.topNode3]
        )
    }

    // MARK: Left nodes
    static var leftNode1: Self {
        NodeDetails(
            name: .leftNode1,
            next: [.leftNode2],
            prev: [.topLeftVertex]
        )
    }

    static var leftNode2: Self {
        NodeDetails(
            name: .leftNode2,
            next: [.leftNode3],
            prev: [.leftNode1]
        )
    }

    static var leftNode3: Self {
        NodeDetails(
            name: .leftNode3,
            next: [.leftNode4],
            prev: [.leftNode2]
        )
    }

    static var leftNode4: Self {
        NodeDetails(
            name: .leftNode4,
            next: [.bottomLeftVertex],
            prev: [.leftNode3]
        )
    }

    // MARK: Right nodes
    static var rightNode1: Self {
        NodeDetails(
            name: .rightNode1,
            next: [.rightNode2],
            prev: [.bottomRightVertex]
        )
    }

    static var rightNode2: Self {
        NodeDetails(
            name: .rightNode2,
            next: [.rightNode3],
            prev: [.rightNode1]
        )
    }

    static var rightNode3: Self {
        NodeDetails(
            name: .rightNode3,
            next: [.rightNode4],
            prev: [.rightNode2]
        )
    }

    static var rightNode4: Self {
        NodeDetails(
            name: .rightNode4,
            next: [.topRightVertex],
            prev: [.rightNode3]
        )
    }

    // MARK: Bottom nodes
    static var bottomNode1: Self {
        NodeDetails(
            name: .bottomNode1,
            next: [.bottomNode2],
            prev: [.bottomLeftVertex]
        )
    }

    static var bottomNode2: Self {
        NodeDetails(
            name: .bottomNode2,
            next: [.bottomNode3],
            prev: [.bottomNode1]
        )
    }

    static var bottomNode3: Self {
        NodeDetails(
            name: .bottomNode3,
            next: [.bottomNode4],
            prev: [.bottomNode2]
        )
    }

    static var bottomNode4: Self {
        NodeDetails(
            name: .bottomNode4,
            next: [.bottomRightVertex],
            prev: [.bottomNode3]
        )
    }
}

// MARK: Inner nodes
extension NodeDetails {
    // Top diagonal nodes
    static var leftTopDiagonal1: Self {
        NodeDetails(
            name: .leftTopDiagonal1,
            next: [.leftTopDiagonal2],
            prev: [.topLeftVertex]
        )
    }

    static var leftTopDiagonal2: Self {
        NodeDetails(
            name: .leftTopDiagonal2,
            next: [.center],
            prev: [.leftTopDiagonal1]
        )
    }

    static var rightTopDiagonal1: Self {
        NodeDetails(
            name: .rightTopDiagonal1,
            next: [.rightTopDiagonal2],
            prev: [.topRightVertex]
        )
    }

    static var rightTopDiagonal2: Self {
        NodeDetails(
            name: .rightTopDiagonal2,
            next: [.center],
            prev: [.rightTopDiagonal1]
        )
    }

    static var center: Self {
        NodeDetails(
            name: .center,
            next: [.leftBottomDiagonal1, .rightBottomDiagonal1],
            prev: [.leftTopDiagonal2, .rightTopDiagonal2]
        )
    }

    // MARK: Bottom diagonal nodes
    static var leftBottomDiagonal1: Self {
        NodeDetails(
            name: .leftBottomDiagonal1,
            next: [.leftBottomDiagonal2],
            prev: [.center]
        )
    }

    static var leftBottomDiagonal2: Self {
        NodeDetails(
            name: .leftBottomDiagonal2,
            next: [.bottomLeftVertex],
            prev: [.leftBottomDiagonal1]
        )
    }

    static var rightBottomDiagonal1: Self {
        NodeDetails(
            name: .rightBottomDiagonal1,
            next: [.rightBottomDiagonal2],
            prev: [.center]
        )
    }

    static var rightBottomDiagonal2: Self {
        NodeDetails(
            name: .rightBottomDiagonal2,
            next: [.bottomRightVertex],
            prev: [.rightBottomDiagonal1]
        )
    }
}
