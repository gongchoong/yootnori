//
//  NodeDetails.swift
//  yootnori
//
//  Created by David Lee on 11/2/24.
//

import Foundation

struct Node: Hashable, Codable {
    let name: NodeName
    let index: Index
    let next: [NodeName]
    let prev: [NodeName]
    
    // Conforming to Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(index)
        hasher.combine(next)
        hasher.combine(prev)
    }
    
    static func == (lhs: Node, rhs: Node) -> Bool {
        lhs.name == rhs.name && lhs.index == rhs.index && lhs.next == rhs.next && lhs.prev == rhs.prev
    }

    func isCenterNode(_ node: Node) -> Bool {
        [.center].contains(node.name)

    }

    func isCornerNode(_ node: Node) -> Bool {
        [.topLeftVertex, .topRightVertex, .bottomRightVertex, .bottomLeftVertex].contains(node.name)
    }
}

// MARK: - Node Definitions
extension Node {
    static var empty: Self {
        Node(
            name: .empty,
            index: .outer(column: 0, row: 0),
            next: [],
            prev: []
        )
    }
    static var topLeftVertex: Self {
        Node(
            name: .topLeftVertex,
            index: Index.outer(column: 0, row: 0),
            next: [.leftTopDiagonal1, .leftNode1],
            prev: [.topNode4]
        )
    }

    static var bottomLeftVertex: Self {
        Node(
            name: .bottomLeftVertex,
            index: Index.outer(column: 0, row: 5),
            next: [.bottomNode1],
            prev: [.leftNode4, .leftBottomDiagonal2]
        )
    }

    static var topRightVertex: Self {
        Node(
            name: .topRightVertex,
            index: Index.outer(column: 5, row: 0),
            next: [.rightTopDiagonal1, .topNode1],
            prev: [.rightNode4]
        )
    }

    static var bottomRightVertex: Self {
        Node(
            name: .bottomRightVertex,
            index: Index.outer(column: 5, row: 5),
            next: [.rightNode1],
            prev: [.bottomNode4, .rightBottomDiagonal2]
        )
    }

    static var topNode1: Self {
        Node(
            name: .topNode1,
            index: Index.outer(column: 4, row: 0),
            next: [.topNode2],
            prev: [.topRightVertex]
        )
    }

    static var topNode2: Self {
        Node(
            name: .topNode2,
            index: Index.outer(column: 3, row: 0),
            next: [.topNode3],
            prev: [.topNode1]
        )
    }

    static var topNode3: Self {
        Node(
            name: .topNode3,
            index: Index.outer(column: 2, row: 0),
            next: [.topNode4],
            prev: [.topNode2]
        )
    }

    static var topNode4: Self {
        Node(
            name: .topNode4,
            index: Index.outer(column: 1, row: 0),
            next: [.topLeftVertex],
            prev: [.topNode3]
        )
    }

    static var leftNode1: Self {
        Node(
            name: .leftNode1,
            index: Index.outer(column: 0, row: 1),
            next: [.leftNode2],
            prev: [.topLeftVertex]
        )
    }

    static var leftNode2: Self {
        Node(
            name: .leftNode2,
            index: Index.outer(column: 0, row: 2),
            next: [.leftNode3],
            prev: [.leftNode1]
        )
    }

    static var leftNode3: Self {
        Node(
            name: .leftNode3,
            index: Index.outer(column: 0, row: 3),
            next: [.leftNode4],
            prev: [.leftNode2]
        )
    }

    static var leftNode4: Self {
        Node(
            name: .leftNode4,
            index: Index.outer(column: 0, row: 4),
            next: [.bottomLeftVertex],
            prev: [.leftNode3]
        )
    }

    static var rightNode1: Self {
        Node(
            name: .rightNode1,
            index: Index.outer(column: 5, row: 4),
            next: [.rightNode2],
            prev: [.bottomRightVertex]
        )
    }

    static var rightNode2: Self {
        Node(
            name: .rightNode2,
            index: Index.outer(column: 5, row: 3),
            next: [.rightNode3],
            prev: [.rightNode1]
        )
    }

    static var rightNode3: Self {
        Node(
            name: .rightNode3,
            index: Index.outer(column: 5, row: 2),
            next: [.rightNode4],
            prev: [.rightNode2]
        )
    }

    static var rightNode4: Self {
        Node(
            name: .rightNode4,
            index: Index.outer(column: 5, row: 1),
            next: [.topRightVertex],
            prev: [.rightNode3]
        )
    }

    static var bottomNode1: Self {
        Node(
            name: .bottomNode1,
            index: Index.outer(column: 1, row: 5),
            next: [.bottomNode2],
            prev: [.bottomLeftVertex]
        )
    }

    static var bottomNode2: Self {
        Node(
            name: .bottomNode2,
            index: Index.outer(column: 2, row: 5),
            next: [.bottomNode3],
            prev: [.bottomNode1]
        )
    }

    static var bottomNode3: Self {
        Node(
            name: .bottomNode3,
            index: Index.outer(column: 3, row: 5),
            next: [.bottomNode4],
            prev: [.bottomNode2]
        )
    }

    static var bottomNode4: Self {
        Node(
            name: .bottomNode4,
            index: Index.outer(column: 4, row: 5),
            next: [.bottomRightVertex],
            prev: [.bottomNode3]
        )
    }

    static var leftTopDiagonal1: Self {
        Node(
            name: .leftTopDiagonal1,
            index: Index.inner(column: 0, row: 0),
            next: [.leftTopDiagonal2],
            prev: [.topLeftVertex]
        )
    }

    static var leftTopDiagonal2: Self {
        Node(
            name: .leftTopDiagonal2,
            index: Index.inner(column: 1, row: 1),
            next: [.center],
            prev: [.leftTopDiagonal1]
        )
    }

    static var rightTopDiagonal1: Self {
        Node(
            name: .rightTopDiagonal1,
            index: Index.inner(column: 4, row: 0),
            next: [.rightTopDiagonal2],
            prev: [.topRightVertex]
        )
    }

    static var rightTopDiagonal2: Self {
        Node(
            name: .rightTopDiagonal2,
            index: Index.inner(column: 3, row: 1),
            next: [.center],
            prev: [.rightTopDiagonal1]
        )
    }

    static var center: Self {
        Node(
            name: .center,
            index: Index.inner(column: 2, row: 2),
            next: [.rightBottomDiagonal1, .leftBottomDiagonal1],
            prev: [.leftTopDiagonal2, .rightTopDiagonal2]
        )
    }

    static var leftBottomDiagonal1: Self {
        Node(
            name: .leftBottomDiagonal1,
            index: Index.inner(column: 1, row: 3),
            next: [.leftBottomDiagonal2],
            prev: [.center]
        )
    }

    static var leftBottomDiagonal2: Self {
        Node(
            name: .leftBottomDiagonal2,
            index: Index.inner(column: 0, row: 4),
            next: [.bottomLeftVertex],
            prev: [.leftBottomDiagonal1]
        )
    }

    static var rightBottomDiagonal1: Self {
        Node(
            name: .rightBottomDiagonal1,
            index: Index.inner(column: 3, row: 3),
            next: [.rightBottomDiagonal2],
            prev: [.center]
        )
    }

    static var rightBottomDiagonal2: Self {
        Node(
            name: .rightBottomDiagonal2,
            index: Index.inner(column: 4, row: 4),
            next: [.bottomRightVertex],
            prev: [.rightBottomDiagonal1]
        )
    }
}

struct TargetNode: Hashable {
    let name: NodeName
    let yootRoll: Yoot
    let isScoreable: Bool

    init(name: NodeName, yootRoll: Yoot, isScoreable: Bool = false) {
        self.name = name
        self.yootRoll = yootRoll
        self.isScoreable = isScoreable
    }
}
