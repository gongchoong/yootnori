//
//  BoardConfig.swift
//  yootnori
//
//  Created by David Lee on 4/19/25.
//

struct BoardConfig {
    static let nodeNames: [NodeName] = [
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
    
    static let nodeRelationships: [NodeName: (next: [NodeName], prev: [NodeName])] = [
        .topLeftVertex: (next: [.leftTopDiagonal1, .leftNode1], prev: [.topNode4]),
        .bottomLeftVertex: (next: [.bottomNode1], prev: [.leftNode4, .leftBottomDiagonal2]),
        .topRightVertex: (next: [.rightTopDiagonal1, .topNode1], prev: [.rightNode4]),
        .bottomRightVertex: (next: [.rightNode1], prev: [.bottomNode4, .rightBottomDiagonal2]),

        .topNode1: (next: [.topNode2], prev: [.topRightVertex]),
        .topNode2: (next: [.topNode3], prev: [.topNode1]),
        .topNode3: (next: [.topNode4], prev: [.topNode2]),
        .topNode4: (next: [.topLeftVertex], prev: [.topNode3]),

        .leftNode1: (next: [.leftNode2], prev: [.topLeftVertex]),
        .leftNode2: (next: [.leftNode3], prev: [.leftNode1]),
        .leftNode3: (next: [.leftNode4], prev: [.leftNode2]),
        .leftNode4: (next: [.bottomLeftVertex], prev: [.leftNode3]),

        .rightNode1: (next: [.rightNode2], prev: [.bottomRightVertex]),
        .rightNode2: (next: [.rightNode3], prev: [.rightNode1]),
        .rightNode3: (next: [.rightNode4], prev: [.rightNode2]),
        .rightNode4: (next: [.topRightVertex], prev: [.rightNode3]),

        .bottomNode1: (next: [.bottomNode2], prev: [.bottomLeftVertex]),
        .bottomNode2: (next: [.bottomNode3], prev: [.bottomNode1]),
        .bottomNode3: (next: [.bottomNode4], prev: [.bottomNode2]),
        .bottomNode4: (next: [.bottomRightVertex], prev: [.bottomNode3]),

        .leftTopDiagonal1: (next: [.leftTopDiagonal2], prev: [.topLeftVertex]),
        .leftTopDiagonal2: (next: [.center], prev: [.leftTopDiagonal1]),

        .rightTopDiagonal1: (next: [.rightTopDiagonal2], prev: [.topRightVertex]),
        .rightTopDiagonal2: (next: [.center], prev: [.rightTopDiagonal1]),

        .center: (next: [.rightBottomDiagonal1, .leftBottomDiagonal1], prev: [.leftTopDiagonal2, .rightTopDiagonal2]),

        .leftBottomDiagonal1: (next: [.leftBottomDiagonal2], prev: [.center]),
        .leftBottomDiagonal2: (next: [.bottomLeftVertex], prev: [.leftBottomDiagonal1]),

        .rightBottomDiagonal1: (next: [.rightBottomDiagonal2], prev: [.center]),
        .rightBottomDiagonal2: (next: [.bottomRightVertex], prev: [.rightBottomDiagonal1])
    ]

    
    static let nodeIndexMap: [NodeName: Index] = [
        .topLeftVertex: .outer(column: 0, row: 0),
        .bottomLeftVertex: .outer(column: 0, row: 5),
        .topRightVertex: .outer(column: 5, row: 0),
        .bottomRightVertex: .outer(column: 5, row: 5),

        .topNode1: .outer(column: 4, row: 0),
        .topNode2: .outer(column: 3, row: 0),
        .topNode3: .outer(column: 2, row: 0),
        .topNode4: .outer(column: 1, row: 0),

        .leftNode1: .outer(column: 0, row: 1),
        .leftNode2: .outer(column: 0, row: 2),
        .leftNode3: .outer(column: 0, row: 3),
        .leftNode4: .outer(column: 0, row: 4),

        .rightNode1: .outer(column: 5, row: 4),
        .rightNode2: .outer(column: 5, row: 3),
        .rightNode3: .outer(column: 5, row: 2),
        .rightNode4: .outer(column: 5, row: 1),

        .bottomNode1: .outer(column: 1, row: 5),
        .bottomNode2: .outer(column: 2, row: 5),
        .bottomNode3: .outer(column: 3, row: 5),
        .bottomNode4: .outer(column: 4, row: 5),

        .leftTopDiagonal1: .inner(column: 0, row: 0),
        .leftTopDiagonal2: .inner(column: 1, row: 1),

        .rightTopDiagonal1: .inner(column: 4, row: 0),
        .rightTopDiagonal2: .inner(column: 3, row: 1),

        .center: .inner(column: 2, row: 2),

        .leftBottomDiagonal1: .inner(column: 1, row: 3),
        .leftBottomDiagonal2: .inner(column: 0, row: 4),

        .rightBottomDiagonal1: .inner(column: 3, row: 3),
        .rightBottomDiagonal2: .inner(column: 4, row: 4)
    ]

}
