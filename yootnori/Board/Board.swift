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
       [Tile(type: .edge, position: .topLeftCorner, paths: [.right, .bottom, .bottomRight]),
        Tile(type: .edge, position: .edgeTop, paths: [.left, .right]),
        Tile(type: .edge, position: .edgeTop, paths: [.left, .right]),
        Tile(type: .edge, position: .edgeTop, paths: [.left, .right]),
        Tile(type: .edge, position: .edgeTop, paths: [.left, .right]),
        Tile(type: .edge, position: .topRightCorner, paths: [.left, .bottom, .bottomLeft])
       ],
       [Tile(type: .edge, position: .edgeLeft, paths: [.top, .bottom]),
        Tile(type: .hidden, position: nil, paths: nil),
        Tile(type: .hidden, position: nil, paths: nil),
        Tile(type: .hidden, position: nil, paths: nil),
        Tile(type: .hidden, position: nil, paths: nil),
        Tile(type: .edge, position: .edgeRight, paths: [.top, .bottom])
       ],
       [Tile(type: .edge, position: .edgeLeft, paths: [.top, .bottom]),
        Tile(type: .hidden, position: nil, paths: nil),
        Tile(type: .hidden, position: nil, paths: nil),
        Tile(type: .hidden, position: nil, paths: nil),
        Tile(type: .hidden, position: nil, paths: nil),
        Tile(type: .edge, position: .edgeRight, paths: [.top, .bottom])
       ],
       [Tile(type: .edge, position: .edgeLeft, paths: [.top, .bottom]),
        Tile(type: .hidden, position: nil, paths: nil),
        Tile(type: .hidden, position: nil, paths: nil),
        Tile(type: .hidden, position: nil, paths: nil),
        Tile(type: .hidden, position: nil, paths: nil),
        Tile(type: .edge, position: .edgeRight, paths: [.top, .bottom])
       ],
       [Tile(type: .edge, position: .edgeLeft, paths: [.top, .bottom]),
        Tile(type: .hidden, position: nil, paths: nil),
        Tile(type: .hidden, position: nil, paths: nil),
        Tile(type: .hidden, position: nil, paths: nil),
        Tile(type: .hidden, position: nil, paths: nil),
        Tile(type: .edge, position: .edgeRight, paths: [.top, .bottom])
       ],
       [Tile(type: .edge, position: .bottomLeftCorner, paths: [.top, .right, .topRight]),
        Tile(type: .edge, position: .edgeBottom, paths: [.left, .right]),
        Tile(type: .edge, position: .edgeBottom, paths: [.left, .right]),
        Tile(type: .edge, position: .edgeBottom, paths: [.left, .right]),
        Tile(type: .edge, position: .edgeBottom, paths: [.left, .right]),
        Tile(type: .edge, position: .bottomRightCorner, paths: [.top, .left, .topLeft])
       ],
   ]
    
    static var innerTileLayout: [[Tile]] = [
        [Tile(type: .inner, position: .diagonalTopLeft, paths: [.topLeft, .bottomRight]),
         Tile(type: .inner, position: nil, paths: nil),
         Tile(type: .inner, position: nil, paths: nil),
         Tile(type: .inner, position: nil, paths: nil),
         Tile(type: .inner, position: .diagonalTopRight, paths: [.topRight, .bottomLeft]),
        ],
        [Tile(type: .inner, position: nil, paths: nil),
         Tile(type: .inner, position: .diagonalTopLeft, paths: [.topLeft, .bottomRight]),
         Tile(type: .inner, position: nil, paths: nil),
         Tile(type: .inner, position: .diagonalTopRight, paths: [.topRight, .bottomLeft]),
         Tile(type: .inner, position: nil, paths: nil),
        ],
        [Tile(type: .inner, position: nil, paths: nil),
         Tile(type: .inner, position: nil, paths: nil),
         Tile(type: .inner, position: .center, paths: [.topRight, .topLeft, .bottomRight, .bottomLeft]),
         Tile(type: .inner, position: nil, paths: nil),
         Tile(type: .inner, position: nil, paths: nil),
        ],
        [Tile(type: .inner, position: nil, paths: nil),
         Tile(type: .inner, position: .diagonalBottomLeft, paths: [.topRight, .bottomLeft]),
         Tile(type: .inner, position: nil, paths: nil),
         Tile(type: .inner, position: .diagonalBottomRight, paths: [.topLeft, .bottomRight]),
         Tile(type: .inner, position: nil, paths: nil),
        ],
        [Tile(type: .inner, position: .diagonalBottomLeft, paths: [.topRight, .bottomLeft]),
         Tile(type: .inner, position: nil, paths: nil),
         Tile(type: .inner, position: nil, paths: nil),
         Tile(type: .inner, position: nil, paths: nil),
         Tile(type: .inner, position: .diagonalBottomRight, paths: [.topLeft, .bottomRight]),
        ],
    ]
}
