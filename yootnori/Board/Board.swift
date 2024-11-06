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
                nodeName: .topLeftVertex
            ),
            Tile(
                type: .edge,
                location: .edgeTop,
                paths: [.left, .right],
                nodeName: .topNode4
            ),
            Tile(
                type: .edge,
                location: .edgeTop,
                paths: [.left, .right],
                nodeName: .topNode3
            ),
            Tile(
                type: .edge,
                location: .edgeTop,
                paths: [.left, .right],
                nodeName: .topNode2
            ),
            Tile(
                type: .edge,
                location: .edgeTop,
                paths: [.left, .right],
                nodeName: .topNode1
            ),
            Tile(
                type: .edge,
                location: .topRightCorner,
                paths: [
                    .left,
                    .bottom,
                    .bottomLeft
                ],
                nodeName: .topRightVertex
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
                nodeName: .leftNode1
            ),
            Tile(type: .hidden, location: nil, paths: nil, nodeName: .empty),
            Tile(type: .hidden, location: nil, paths: nil, nodeName: .empty),
            Tile(type: .hidden, location: nil, paths: nil, nodeName: .empty),
            Tile(type: .hidden, location: nil, paths: nil, nodeName: .empty),
            Tile(
                type: .edge,
                location: .edgeRight,
                paths: [.top, .bottom],
                nodeName: .rightNode4
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
                nodeName: .leftNode2
            ),
            Tile(type: .hidden, location: nil, paths: nil, nodeName: .empty),
            Tile(type: .hidden, location: nil, paths: nil, nodeName: .empty),
            Tile(type: .hidden, location: nil, paths: nil, nodeName: .empty),
            Tile(type: .hidden, location: nil, paths: nil, nodeName: .empty),
            Tile(
                type: .edge,
                location: .edgeRight,
                paths: [.top, .bottom],
                nodeName: .rightNode3
            )
       ],
        [
            Tile(
                type: .edge,
                location: .edgeLeft,
                paths: [.top, .bottom],
                nodeName: .leftNode3
            ),
            Tile(type: .hidden, location: nil, paths: nil, nodeName: .empty),
            Tile(type: .hidden, location: nil, paths: nil, nodeName: .empty),
            Tile(type: .hidden, location: nil, paths: nil, nodeName: .empty),
            Tile(type: .hidden, location: nil, paths: nil, nodeName: .empty),
            Tile(
                type: .edge,
                location: .edgeRight,
                paths: [.top, .bottom],
                nodeName: .rightNode2
            )
       ],
        [
            Tile(
                type: .edge,
                location: .edgeLeft,
                paths: [.top, .bottom],
                nodeName: .leftNode4
            ),
            Tile(type: .hidden, location: nil, paths: nil, nodeName: .empty),
            Tile(type: .hidden, location: nil, paths: nil, nodeName: .empty),
            Tile(type: .hidden, location: nil, paths: nil, nodeName: .empty),
            Tile(type: .hidden, location: nil, paths: nil, nodeName: .empty),
            Tile(
                type: .edge,
                location: .edgeRight,
                paths: [.top, .bottom],
                nodeName: .rightNode1
            )
       ],
        [
            Tile(
                type: .edge,
                location: .bottomLeftCorner,
                paths: [.top, .right, .topRight],
                nodeName: .bottomLeftVertex
            ),
            Tile(
                type: .edge,
                location: .edgeBottom,
                paths: [.left, .right],
                nodeName: .bottomNode1
            ),
            Tile(
                type: .edge,
                location: .edgeBottom,
                paths: [.left, .right],
                nodeName: .bottomNode2
            ),
            Tile(
                type: .edge,
                location: .edgeBottom,
                paths: [.left, .right],
                nodeName: .bottomNode3
            ),
            Tile(
                type: .edge,
                location: .edgeBottom,
                paths: [.left, .right],
                nodeName: .bottomNode4
            ),
            Tile(
                type: .edge,
                location: .bottomRightCorner,
                paths: [.top, .left, .topLeft],
                nodeName: .bottomRightVertex
            )
       ],
   ]
    
    static var innerTileLayout: [[Tile]] = [
        [
            Tile(
                type: .inner,
                location: .diagonalTopLeft,
                paths: [.topLeft, .bottomRight],
                nodeName: .leftTopDiagonal1
            ),
            Tile(type: .inner, location: nil, paths: nil, nodeName: .empty),
            Tile(type: .inner, location: nil, paths: nil, nodeName: .empty),
            Tile(type: .inner, location: nil, paths: nil, nodeName: .empty),
            Tile(
                type: .inner,
                location: .diagonalTopRight,
                paths: [.topRight, .bottomLeft],
                nodeName: .rightTopDiagonal1
            ),
        ],
        [
            Tile(type: .inner, location: nil, paths: nil, nodeName: .empty),
            Tile(
                type: .inner,
                location: .diagonalTopLeft,
                paths: [.topLeft, .bottomRight],
                nodeName: .leftTopDiagonal2
            ),
            Tile(type: .inner, location: nil, paths: nil, nodeName: .empty),
            Tile(
                type: .inner,
                location: .diagonalTopRight,
                paths: [.topRight, .bottomLeft],
                nodeName: .rightTopDiagonal2
            ),
            Tile(type: .inner, location: nil, paths: nil, nodeName: .empty),
        ],
        [
            Tile(type: .inner, location: nil, paths: nil, nodeName: .empty),
            Tile(type: .inner, location: nil, paths: nil, nodeName: .empty),
            Tile(
                type: .inner,
                location: .center,
                paths: [.topRight, .topLeft, .bottomRight, .bottomLeft],
                nodeName: .center
            ),
            Tile(type: .inner, location: nil, paths: nil, nodeName: .empty),
            Tile(type: .inner, location: nil, paths: nil, nodeName: .empty),
        ],
        [
            Tile(type: .inner, location: nil, paths: nil, nodeName: .empty),
            Tile(
                type: .inner,
                location: .diagonalBottomLeft,
                paths: [.topRight, .bottomLeft],
                nodeName: .leftBottomDiagonal1
            ),
            Tile(type: .inner, location: nil, paths: nil, nodeName: .empty),
            Tile(
                type: .inner,
                location: .diagonalBottomRight,
                paths: [.topLeft, .bottomRight],
                nodeName: .rightBottomDiagonal1
            ),
            Tile(type: .inner, location: nil, paths: nil, nodeName: .empty),
        ],
        [
            Tile(
                type: .inner,
                location: .diagonalBottomLeft,
                paths: [.topRight, .bottomLeft],
                nodeName: .leftBottomDiagonal2
            ),
            Tile(type: .inner, location: nil, paths: nil, nodeName: .empty),
            Tile(type: .inner, location: nil, paths: nil, nodeName: .empty),
            Tile(type: .inner, location: nil, paths: nil, nodeName: .empty),
            Tile(
                type: .inner,
                location: .diagonalBottomRight,
                paths: [.topLeft, .bottomRight],
                nodeName: .rightBottomDiagonal2
            ),
        ],
    ]
}
