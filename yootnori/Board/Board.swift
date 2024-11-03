//
//  Board.swift
//  yootnori
//
//  Created by David Lee on 9/29/24.
//

import Foundation

struct Board {
    
}

extension Board {
    static var edgeTileLayout: [[Tile]] = [
        [
            Tile(
                type: .edge,
                location: .topLeftCorner,
                paths: [.right, .bottom, .bottomRight],
                nodeDetails: .topLeftVertex
            ),
            Tile(
                type: .edge,
                location: .edgeTop,
                paths: [.left, .right],
                nodeDetails: .topNode4
            ),
            Tile(
                type: .edge,
                location: .edgeTop,
                paths: [.left, .right],
                nodeDetails: .topNode3
            ),
            Tile(
                type: .edge,
                location: .edgeTop,
                paths: [.left, .right],
                nodeDetails: .topNode2
            ),
            Tile(
                type: .edge,
                location: .edgeTop,
                paths: [.left, .right],
                nodeDetails: .topNode1
            ),
            Tile(
                type: .edge,
                location: .topRightCorner,
                paths: [
                    .left,
                    .bottom,
                    .bottomLeft
                ],
                nodeDetails: .topRightVertex
            )
       ],
        [
            Tile(
                type: .edge,
                location: .edgeLeft,
                paths: [
                    .top,
                    .bottom
                ],
                nodeDetails: .leftNode1
            ),
            Tile(type: .hidden, location: nil, paths: nil, nodeDetails: .empty),
            Tile(type: .hidden, location: nil, paths: nil, nodeDetails: .empty),
            Tile(type: .hidden, location: nil, paths: nil, nodeDetails: .empty),
            Tile(type: .hidden, location: nil, paths: nil, nodeDetails: .empty),
            Tile(
                type: .edge,
                location: .edgeRight,
                paths: [.top, .bottom],
                nodeDetails: .rightNode4
            )
       ],
        [
            Tile(
                type: .edge,
                location: .edgeLeft,
                paths: [
                    .top,
                    .bottom
                ],
                nodeDetails: .leftNode2
            ),
            Tile(type: .hidden, location: nil, paths: nil, nodeDetails: .empty),
            Tile(type: .hidden, location: nil, paths: nil, nodeDetails: .empty),
            Tile(type: .hidden, location: nil, paths: nil, nodeDetails: .empty),
            Tile(type: .hidden, location: nil, paths: nil, nodeDetails: .empty),
            Tile(
                type: .edge,
                location: .edgeRight,
                paths: [.top, .bottom],
                nodeDetails: .rightNode3
            )
       ],
        [
            Tile(
                type: .edge,
                location: .edgeLeft,
                paths: [.top, .bottom],
                nodeDetails: .leftNode3
            ),
            Tile(type: .hidden, location: nil, paths: nil, nodeDetails: .empty),
            Tile(type: .hidden, location: nil, paths: nil, nodeDetails: .empty),
            Tile(type: .hidden, location: nil, paths: nil, nodeDetails: .empty),
            Tile(type: .hidden, location: nil, paths: nil, nodeDetails: .empty),
            Tile(
                type: .edge,
                location: .edgeRight,
                paths: [.top, .bottom],
                nodeDetails: .rightNode2
            )
       ],
        [
            Tile(
                type: .edge,
                location: .edgeLeft,
                paths: [.top, .bottom],
                nodeDetails: .leftNode4
            ),
            Tile(type: .hidden, location: nil, paths: nil, nodeDetails: .empty),
            Tile(type: .hidden, location: nil, paths: nil, nodeDetails: .empty),
            Tile(type: .hidden, location: nil, paths: nil, nodeDetails: .empty),
            Tile(type: .hidden, location: nil, paths: nil, nodeDetails: .empty),
            Tile(
                type: .edge,
                location: .edgeRight,
                paths: [.top, .bottom],
                nodeDetails: .rightNode1
            )
       ],
        [
            Tile(
                type: .edge,
                location: .bottomLeftCorner,
                paths: [.top, .right, .topRight],
                nodeDetails: .bottomLeftVertex
            ),
            Tile(
                type: .edge,
                location: .edgeBottom,
                paths: [.left, .right],
                nodeDetails: .bottomNode1
            ),
            Tile(
                type: .edge,
                location: .edgeBottom,
                paths: [.left, .right],
                nodeDetails: .bottomNode2
            ),
            Tile(
                type: .edge,
                location: .edgeBottom,
                paths: [.left, .right],
                nodeDetails: .bottomNode3
            ),
            Tile(
                type: .edge,
                location: .edgeBottom,
                paths: [.left, .right],
                nodeDetails: .bottomNode4
            ),
            Tile(
                type: .edge,
                location: .bottomRightCorner,
                paths: [.top, .left, .topLeft],
                nodeDetails: .bottomRightVertex
            )
       ],
   ]
    
    static var innerTileLayout: [[Tile]] = [
        [
            Tile(
                type: .inner,
                location: .diagonalTopLeft,
                paths: [.topLeft, .bottomRight],
                nodeDetails: .leftTopDiagonal1
            ),
            Tile(type: .inner, location: nil, paths: nil, nodeDetails: .empty),
            Tile(type: .inner, location: nil, paths: nil, nodeDetails: .empty),
            Tile(type: .inner, location: nil, paths: nil, nodeDetails: .empty),
            Tile(
                type: .inner,
                location: .diagonalTopRight,
                paths: [.topRight, .bottomLeft],
                nodeDetails: .rightTopDiagonal1
            ),
        ],
        [
            Tile(type: .inner, location: nil, paths: nil, nodeDetails: .empty),
            Tile(
                type: .inner,
                location: .diagonalTopLeft,
                paths: [.topLeft, .bottomRight],
                nodeDetails: .leftTopDiagonal2
            ),
            Tile(type: .inner, location: nil, paths: nil, nodeDetails: .empty),
            Tile(
                type: .inner,
                location: .diagonalTopRight,
                paths: [.topRight, .bottomLeft],
                nodeDetails: .rightTopDiagonal2
            ),
            Tile(type: .inner, location: nil, paths: nil, nodeDetails: .empty),
        ],
        [
            Tile(type: .inner, location: nil, paths: nil, nodeDetails: .empty),
            Tile(type: .inner, location: nil, paths: nil, nodeDetails: .empty),
            Tile(
                type: .inner,
                location: .center,
                paths: [.topRight, .topLeft, .bottomRight, .bottomLeft],
                nodeDetails: .center
            ),
            Tile(type: .inner, location: nil, paths: nil, nodeDetails: .empty),
            Tile(type: .inner, location: nil, paths: nil, nodeDetails: .empty),
        ],
        [
            Tile(type: .inner, location: nil, paths: nil, nodeDetails: .empty),
            Tile(
                type: .inner,
                location: .diagonalBottomLeft,
                paths: [.topRight, .bottomLeft],
                nodeDetails: .leftBottomDiagonal1
            ),
            Tile(type: .inner, location: nil, paths: nil, nodeDetails: .empty),
            Tile(
                type: .inner,
                location: .diagonalBottomRight,
                paths: [.topLeft, .bottomRight],
                nodeDetails: .rightBottomDiagonal1
            ),
            Tile(type: .inner, location: nil, paths: nil, nodeDetails: .empty),
        ],
        [
            Tile(
                type: .inner,
                location: .diagonalBottomLeft,
                paths: [.topRight, .bottomLeft],
                nodeDetails: .leftBottomDiagonal2
            ),
            Tile(type: .inner, location: nil, paths: nil, nodeDetails: .empty),
            Tile(type: .inner, location: nil, paths: nil, nodeDetails: .empty),
            Tile(type: .inner, location: nil, paths: nil, nodeDetails: .empty),
            Tile(
                type: .inner,
                location: .diagonalBottomRight,
                paths: [.topLeft, .bottomRight],
                nodeDetails: .rightBottomDiagonal2
            ),
        ],
    ]
}
