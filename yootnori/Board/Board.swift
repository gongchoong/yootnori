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
                node: .topLeftVertex
            ),
            Tile(
                type: .edge,
                location: .edgeTop,
                paths: [.left, .right],
                node: .topNode4
            ),
            Tile(
                type: .edge,
                location: .edgeTop,
                paths: [.left, .right],
                node: Node(
                    type: .topNode3,
                    next: [.topNode4],
                    prev: [.topNode2]
                )
            ),
            Tile(
                type: .edge,
                location: .edgeTop,
                paths: [.left, .right],
                node: Node(
                    type: .topNode2,
                    next: [.topNode3],
                    prev: [.topNode1]
                )
            ),
            Tile(
                type: .edge,
                location: .edgeTop,
                paths: [.left, .right],
                node: Node(
                    type: .topNode1,
                    next: [.topNode2],
                    prev: [.topRightVertex]
                )
            ),
            Tile(
                type: .edge,
                location: .topRightCorner,
                paths: [
                    .left,
                    .bottom,
                    .bottomLeft
                ],
                node: Node(
                    type: .topRightVertex,
                    next: [.topNode1, .rightTopDiagonal1],
                    prev: [.rightNode4]
                )
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
                node: Node(
                    type: .leftNode1,
                    next: [.leftNode2],
                    prev: [.topLeftVertex]
                )
            ),
            Tile(type: .hidden, location: nil, paths: nil, node: .empty),
            Tile(type: .hidden, location: nil, paths: nil, node: .empty),
            Tile(type: .hidden, location: nil, paths: nil, node: .empty),
            Tile(type: .hidden, location: nil, paths: nil, node: .empty),
            Tile(
                type: .edge,
                location: .edgeRight,
                paths: [.top, .bottom],
                node: Node(
                    type: .rightNode4,
                    next: [.topRightVertex],
                    prev: [.rightNode3]
                )
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
                node: Node(
                    type: .leftNode2,
                    next: [.leftNode3],
                    prev: [.leftNode1]
                )
            ),
            Tile(type: .hidden, location: nil, paths: nil, node: .empty),
            Tile(type: .hidden, location: nil, paths: nil, node: .empty),
            Tile(type: .hidden, location: nil, paths: nil, node: .empty),
            Tile(type: .hidden, location: nil, paths: nil, node: .empty),
            Tile(
                type: .edge,
                location: .edgeRight,
                paths: [.top, .bottom],
                node: Node(
                    type: .rightNode3,
                    next: [.rightNode4],
                    prev: [.rightNode2]
                )
            )
       ],
        [
            Tile(
                type: .edge,
                location: .edgeLeft,
                paths: [.top, .bottom],
                node: Node(
                    type: .leftNode3,
                    next: [.leftNode4],
                    prev: [.leftNode2]
                )
            ),
            Tile(type: .hidden, location: nil, paths: nil, node: .empty),
            Tile(type: .hidden, location: nil, paths: nil, node: .empty),
            Tile(type: .hidden, location: nil, paths: nil, node: .empty),
            Tile(type: .hidden, location: nil, paths: nil, node: .empty),
            Tile(
                type: .edge,
                location: .edgeRight,
                paths: [.top, .bottom],
                node: Node(
                    type: .rightNode2,
                    next: [.rightNode3],
                    prev: [.rightNode1]
                )
            )
       ],
        [
            Tile(
                type: .edge,
                location: .edgeLeft,
                paths: [.top, .bottom],
                node: Node(
                    type: .leftNode4,
                    next: [.bottomLeftVertex],
                    prev: [.leftNode3]
                )
            ),
            Tile(type: .hidden, location: nil, paths: nil, node: .empty),
            Tile(type: .hidden, location: nil, paths: nil, node: .empty),
            Tile(type: .hidden, location: nil, paths: nil, node: .empty),
            Tile(type: .hidden, location: nil, paths: nil, node: .empty),
            Tile(
                type: .edge,
                location: .edgeRight,
                paths: [.top, .bottom],
                node: Node(
                    type: .rightNode1,
                    next: [.rightNode2],
                    prev: [.bottomRightVertex]
                )
            )
       ],
        [
            Tile(
                type: .edge,
                location: .bottomLeftCorner,
                paths: [.top, .right, .topRight],
                node: Node(
                    type: .bottomLeftVertex,
                    next: [.bottomNode1],
                    prev: [.leftNode4, .leftBottomDiagonal2]
                )
            ),
            Tile(
                type: .edge,
                location: .edgeBottom,
                paths: [.left, .right],
                node: Node(
                    type: .bottomNode1,
                    next: [.bottomNode2],
                    prev: [.bottomLeftVertex]
                )
            ),
            Tile(
                type: .edge,
                location: .edgeBottom,
                paths: [.left, .right],
                node: Node(
                    type: .bottomNode2,
                    next: [.bottomNode3],
                    prev: [.bottomNode1]
                )
            ),
            Tile(
                type: .edge,
                location: .edgeBottom,
                paths: [.left, .right],
                node: Node(
                    type: .bottomNode3,
                    next: [.bottomNode4],
                    prev: [.bottomNode2]
                )
            ),
            Tile(
                type: .edge,
                location: .edgeBottom,
                paths: [.left, .right],
                node: Node(
                    type: .bottomNode4,
                    next: [.bottomRightVertex],
                    prev: [.bottomNode3]
                )
            ),
            Tile(
                type: .edge,
                location: .bottomRightCorner,
                paths: [.top, .left, .topLeft],
                node: Node(
                    type: .bottomRightVertex,
                    next: [.rightNode1],
                    prev: [.bottomNode4, .rightBottomDiagonal2]
                )
            )
       ],
   ]
    
    static var innerTileLayout: [[Tile]] = [
        [
            Tile(
                type: .inner,
                location: .diagonalTopLeft,
                paths: [.topLeft, .bottomRight],
                node: Node(
                    type: .leftTopDiagonal1,
                    next: [.leftTopDiagonal2],
                    prev: [.topLeftVertex]
                )
            ),
            Tile(type: .inner, location: nil, paths: nil, node: .empty),
            Tile(type: .inner, location: nil, paths: nil, node: .empty),
            Tile(type: .inner, location: nil, paths: nil, node: .empty),
            Tile(
                type: .inner,
                location: .diagonalTopRight,
                paths: [.topRight, .bottomLeft],
                node: Node(
                    type: .rightTopDiagonal1,
                    next: [.rightTopDiagonal2],
                    prev: [.topRightVertex]
                )
            ),
        ],
        [
            Tile(type: .inner, location: nil, paths: nil, node: .empty),
            Tile(
                type: .inner,
                location: .diagonalTopLeft,
                paths: [.topLeft, .bottomRight],
                node: Node(
                    type: .leftTopDiagonal2,
                    next: [.center],
                    prev: [.leftTopDiagonal1]
                )
            ),
            Tile(type: .inner, location: nil, paths: nil, node: .empty),
            Tile(
                type: .inner,
                location: .diagonalTopRight,
                paths: [.topRight, .bottomLeft],
                node: Node(
                    type: .rightTopDiagonal2,
                    next: [.center],
                    prev: [.rightTopDiagonal1]
                )
            ),
            Tile(type: .inner, location: nil, paths: nil, node: .empty),
        ],
        [
            Tile(type: .inner, location: nil, paths: nil, node: .empty),
            Tile(type: .inner, location: nil, paths: nil, node: .empty),
            Tile(
                type: .inner,
                location: .center,
                paths: [.topRight, .topLeft, .bottomRight, .bottomLeft],
                node: Node(
                    type: .center,
                    next: [.leftBottomDiagonal1, .rightBottomDiagonal1],
                    prev: [.leftTopDiagonal2, .rightTopDiagonal2]
                )
            ),
            Tile(type: .inner, location: nil, paths: nil, node: .empty),
            Tile(type: .inner, location: nil, paths: nil, node: .empty),
        ],
        [
            Tile(type: .inner, location: nil, paths: nil, node: .empty),
            Tile(
                type: .inner,
                location: .diagonalBottomLeft,
                paths: [.topRight, .bottomLeft],
                node: Node(
                    type: .leftBottomDiagonal1,
                    next: [.leftBottomDiagonal2],
                    prev: [.center]
                )
            ),
            Tile(type: .inner, location: nil, paths: nil, node: .empty),
            Tile(
                type: .inner,
                location: .diagonalBottomRight,
                paths: [.topLeft, .bottomRight],
                node: Node(
                    type: .rightBottomDiagonal1,
                    next: [.rightBottomDiagonal2],
                    prev: [.center]
                )
            ),
            Tile(type: .inner, location: nil, paths: nil, node: .empty),
        ],
        [
            Tile(
                type: .inner,
                location: .diagonalBottomLeft,
                paths: [.topRight, .bottomLeft],
                node: Node(
                    type: .leftBottomDiagonal2,
                    next: [.bottomLeftVertex],
                    prev: [.leftBottomDiagonal1]
                )
            ),
            Tile(type: .inner, location: nil, paths: nil, node: .empty),
            Tile(type: .inner, location: nil, paths: nil, node: .empty),
            Tile(type: .inner, location: nil, paths: nil, node: .empty),
            Tile(
                type: .inner,
                location: .diagonalBottomRight,
                paths: [.topLeft, .bottomRight],
                node: Node(
                    type: .rightBottomDiagonal2,
                    next: [.bottomRightVertex],
                    prev: [.rightBottomDiagonal1]
                )
            ),
        ],
    ]
}
