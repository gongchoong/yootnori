//
//  TilePosition.swift
//  yootnori
//
//  Created by David Lee on 10/29/24.
//

import Foundation

// Unique node name assigned for each visible tile on the board.
//  TLV --- TN4 --- TN3 --- TN2 --- TN1 --- TRV
//   |    \                              /   |
//  LN1    LTD1                     RTD1    RN4
//   |       \                      /        |
//  LN2        LTD2             RTD2        RN3
//   |                CENTER                 |
//  LN3        LBD1             RBD1        RN2
//   |       /                      \        |
//  LN4    LBD2                     RBD2    RN1
//   |   /                                \  |
//  BLV --- BN1 --- BN2 --- BN3 --- BN4 --- BRV
enum NodeName: Int, Equatable, CaseIterable, Codable {
    case bottomRightVertex = 0
    case rightNode1
    case rightNode2
    case rightNode3
    case rightNode4
    case topRightVertex
    case topNode1
    case topNode2
    case topNode3
    case topNode4
    case topLeftVertex
    case leftNode1
    case leftNode2
    case leftNode3
    case leftNode4
    case bottomLeftVertex
    case bottomNode1
    case bottomNode2
    case bottomNode3
    case bottomNode4
    case leftBottomDiagonal1
    case leftBottomDiagonal2
    case leftTopDiagonal1
    case leftTopDiagonal2
    case rightTopDiagonal1
    case rightTopDiagonal2
    case center
    case rightBottomDiagonal1
    case rightBottomDiagonal2
    case empty
}

extension NodeName {
    var isStartNode: Bool {
        return self == .bottomRightVertex
    }

    var isTopVertexNode: Bool {
        return [.topLeftVertex, .topRightVertex].contains(self)
    }

    var isInnerNode: Bool {
        return [.leftTopDiagonal1, .leftTopDiagonal2, .leftBottomDiagonal1, .leftBottomDiagonal2, .rightTopDiagonal1, .rightTopDiagonal2, .rightBottomDiagonal1, .rightBottomDiagonal2, .center].contains(self)
    }

    var isBottomRightDiagonalNode: Bool {
        return [.rightBottomDiagonal1, .rightBottomDiagonal2].contains(self)
    }

    var isBottomLeftDiagonalNode: Bool {
        return [.leftBottomDiagonal1, .leftBottomDiagonal2].contains(self)
    }

    var isTopRightDiagonalNode: Bool {
        return [.rightTopDiagonal1, .rightTopDiagonal2].contains(self)
    }

    var isTopLeftDiagonalNode: Bool {
        return [.leftTopDiagonal1, .leftTopDiagonal2].contains(self)
    }

    var isCornerNode: Bool {
        return [.topLeftVertex, .topRightVertex, .bottomRightVertex, .bottomLeftVertex].contains(self)
    }

    var isCenterNode: Bool {
        return self == .center
    }
}
