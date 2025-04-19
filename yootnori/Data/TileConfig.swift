//
//  TileConfig.swift
//  yootnori
//
//  Created by David Lee on 4/19/25.
//

struct TileConfig {
    
    static let tileTypeMap: [NodeName: TileType] = [
        .topLeftVertex: .edge, .topRightVertex: .edge, .bottomLeftVertex: .edge, .bottomRightVertex: .edge,
        .topNode1: .edge, .topNode2: .edge, .topNode3: .edge, .topNode4: .edge,
        .leftNode1: .edge, .leftNode2: .edge, .leftNode3: .edge, .leftNode4: .edge,
        .rightNode1: .edge, .rightNode2: .edge, .rightNode3: .edge, .rightNode4: .edge,
        .bottomNode1: .edge, .bottomNode2: .edge, .bottomNode3: .edge, .bottomNode4: .edge,
        .leftTopDiagonal1: .inner, .leftTopDiagonal2: .inner,
        .rightTopDiagonal1: .inner, .rightTopDiagonal2: .inner,
        .center: .inner,
        .leftBottomDiagonal1: .inner, .leftBottomDiagonal2: .inner,
        .rightBottomDiagonal1: .inner, .rightBottomDiagonal2: .inner
    ]

    static let tileLocationMap: [NodeName: TileLocation] = [
        .topLeftVertex: .topLeftCorner, .topRightVertex: .topRightCorner,
        .bottomLeftVertex: .bottomLeftCorner, .bottomRightVertex: .bottomRightCorner,

        .topNode1: .edgeTop, .topNode2: .edgeTop, .topNode3: .edgeTop, .topNode4: .edgeTop,
        .bottomNode1: .edgeBottom, .bottomNode2: .edgeBottom, .bottomNode3: .edgeBottom, .bottomNode4: .edgeBottom,
        .leftNode1: .edgeLeft, .leftNode2: .edgeLeft, .leftNode3: .edgeLeft, .leftNode4: .edgeLeft,
        .rightNode1: .edgeRight, .rightNode2: .edgeRight, .rightNode3: .edgeRight, .rightNode4: .edgeRight,

        .leftTopDiagonal1: .diagonalTopLeft, .leftTopDiagonal2: .diagonalTopLeft,
        .rightTopDiagonal1: .diagonalTopRight, .rightTopDiagonal2: .diagonalTopRight,
        .center: .center,
        .leftBottomDiagonal1: .diagonalBottomLeft, .leftBottomDiagonal2: .diagonalBottomLeft,
        .rightBottomDiagonal1: .diagonalBottomRight, .rightBottomDiagonal2: .diagonalBottomRight
    ]

    static let tilePathMap: [NodeName: [TilePath]] = [
        .topLeftVertex: [.right, .bottom, .bottomRight],
        .topRightVertex: [.left, .bottom, .bottomLeft],
        .bottomLeftVertex: [.top, .right, .topRight],
        .bottomRightVertex: [.top, .left, .topLeft],

        .topNode1: [.left, .right], .topNode2: [.left, .right],
        .topNode3: [.left, .right], .topNode4: [.left, .right],
        .bottomNode1: [.left, .right], .bottomNode2: [.left, .right],
        .bottomNode3: [.left, .right], .bottomNode4: [.left, .right],

        .leftNode1: [.top, .bottom], .leftNode2: [.top, .bottom],
        .leftNode3: [.top, .bottom], .leftNode4: [.top, .bottom],
        .rightNode1: [.top, .bottom], .rightNode2: [.top, .bottom],
        .rightNode3: [.top, .bottom], .rightNode4: [.top, .bottom],

        .leftTopDiagonal1: [.topLeft, .bottomRight], .leftTopDiagonal2: [.topLeft, .bottomRight],
        .rightTopDiagonal1: [.topRight, .bottomLeft], .rightTopDiagonal2: [.topRight, .bottomLeft],
        .leftBottomDiagonal1: [.topRight, .bottomLeft], .leftBottomDiagonal2: [.topRight, .bottomLeft],
        .rightBottomDiagonal1: [.topLeft, .bottomRight], .rightBottomDiagonal2: [.topLeft, .bottomRight],

        .center: [.topLeft, .topRight, .bottomLeft, .bottomRight]
    ]

    static let tileRelationshipMap: [NodeName: (next: [NodeName], prev: [NodeName])] = [
        .topLeftVertex: ([.topNode4], []),
        .topNode4: ([.topNode3], [.topLeftVertex]),
        .topNode3: ([.topNode2], [.topNode4]),
        .topNode2: ([.topNode1], [.topNode3]),
        .topNode1: ([.topRightVertex], [.topNode2]),
        .topRightVertex: ([], [.topNode1]),

        .bottomLeftVertex: ([.bottomNode1], []),
        .bottomNode1: ([.bottomNode2], [.bottomLeftVertex]),
        .bottomNode2: ([.bottomNode3], [.bottomNode1]),
        .bottomNode3: ([.bottomNode4], [.bottomNode2]),
        .bottomNode4: ([.bottomRightVertex], [.bottomNode3]),
        .bottomRightVertex: ([], [.bottomNode4]),

        // You can add more relationships for inner tiles if needed
    ]

    static let edgeTileLayoutNames: [[NodeName]] = [
        [.topLeftVertex, .topNode4, .topNode3, .topNode2, .topNode1, .topRightVertex],
        [.leftNode1, .empty, .empty, .empty, .empty, .rightNode4],
        [.leftNode2, .empty, .empty, .empty, .empty, .rightNode3],
        [.leftNode3, .empty, .empty, .empty, .empty, .rightNode2],
        [.leftNode4, .empty, .empty, .empty, .empty, .rightNode1],
        [.bottomLeftVertex, .bottomNode1, .bottomNode2, .bottomNode3, .bottomNode4, .bottomRightVertex]
    ]

    static let innerTileLayoutNames: [[NodeName]] = [
        [.leftTopDiagonal1, .empty, .empty, .empty, .rightTopDiagonal1],
        [.empty, .leftTopDiagonal2, .empty, .rightTopDiagonal2, .empty],
        [.empty, .empty, .center, .empty, .empty],
        [.empty, .leftBottomDiagonal1, .empty, .rightBottomDiagonal1, .empty],
        [.leftBottomDiagonal2, .empty, .empty, .empty, .rightBottomDiagonal2]
    ]
}
