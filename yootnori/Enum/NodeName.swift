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
enum NodeName: String, Equatable, CaseIterable {
    case bottomRightVertex
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
    case leftTopDiagonal1
    case leftTopDiagonal2
    case leftBottomDiagonal1
    case leftBottomDiagonal2
    case rightTopDiagonal1
    case rightTopDiagonal2
    case rightBottomDiagonal1
    case rightBottomDiagonal2
    case center
    case empty
}

extension NodeName {
    var isVertex: Bool {
        let vertices: [Self] = [.bottomRightVertex, .topRightVertex, .topLeftVertex, .bottomLeftVertex, .center]
        return vertices.contains(self)
    }

    var isInnerNode: Bool {
        let innerNodes: [Self] = [.leftTopDiagonal1, .leftTopDiagonal2, .leftBottomDiagonal1, .leftBottomDiagonal2, .rightTopDiagonal1, .rightTopDiagonal2, .rightBottomDiagonal1, .rightBottomDiagonal2, .center]
        return innerNodes.contains(self)
    }
}
