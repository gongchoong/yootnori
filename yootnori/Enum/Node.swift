//
//  TilePosition.swift
//  yootnori
//
//  Created by David Lee on 10/29/24.
//

import Foundation

// Unique node position assigned for each visible tile on the board.
//  TLV --- TE4 --- TE3 --- TE2 --- TE1 --- TRV
//   |    \                              /   |
//  LE1    LTD1                     RTD1    RE4
//   |       \                      /        |
//  LE2        LTD2             RTD2        RE3
//   |                CENTER                 |
//  LE3        LBD2             RBD2        RE2
//   |       /                      \        |
//  LE4    LBD1                     RBD1    RE1
//   |   /                                \  |
//  BLV --- BE1 --- BE2 --- BE3 --- BE4 --- BRV
enum Node {
    case bottomRightVertex
    case rightEdge1
    case rightEdge2
    case rightEdge3
    case rightEdge4
    case topRightVertex
    case topEdge1
    case topEdge2
    case topEdge3
    case topEdge4
    case topLeftVertex
    case leftEdge1
    case leftEdge2
    case leftEdge3
    case leftEdge4
    case bottomLeftVertex
    case bottomEdge1
    case bottomEdge2
    case bottomEdge3
    case bottomEdge4
    case leftTopDiagonal1
    case leftTopDiagonal2
    case leftBottomDiagonal1
    case leftBottomDiagonal2
    case rightTopDiagonal1
    case rightTopDiagonal2
    case rightBottomDiagonal1
    case rightBottomDiagonal2
    case center
}
