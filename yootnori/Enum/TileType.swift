//
//  TileType.swift
//  yootnori
//
//  Created by David Lee on 9/29/24.
//

enum TileType: Codable {
    case edge
    case hidden
    case inner
    case stage
}

enum TileLocation: Codable {
    case topLeftCorner
    case topRightCorner
    case bottomRightCorner
    case bottomLeftCorner
    case center
    case edgeTop
    case edgeBottom
    case edgeRight
    case edgeLeft
    case diagonalTopLeft
    case diagonalTopRight
    case diagonalBottomRight
    case diagonalBottomLeft
}

enum TilePath: Codable {
    case top
    case left
    case right
    case bottom
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
}
