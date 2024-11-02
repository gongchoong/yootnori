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
       [Tile(type: .edge, location: .topLeftCorner, paths: [.right, .bottom, .bottomRight]),
        Tile(type: .edge, location: .edgeTop, paths: [.left, .right]),
        Tile(type: .edge, location: .edgeTop, paths: [.left, .right]),
        Tile(type: .edge, location: .edgeTop, paths: [.left, .right]),
        Tile(type: .edge, location: .edgeTop, paths: [.left, .right]),
        Tile(type: .edge, location: .topRightCorner, paths: [.left, .bottom, .bottomLeft])
       ],
       [Tile(type: .edge, location: .edgeLeft, paths: [.top, .bottom]),
        Tile(type: .hidden, location: nil, paths: nil),
        Tile(type: .hidden, location: nil, paths: nil),
        Tile(type: .hidden, location: nil, paths: nil),
        Tile(type: .hidden, location: nil, paths: nil),
        Tile(type: .edge, location: .edgeRight, paths: [.top, .bottom])
       ],
       [Tile(type: .edge, location: .edgeLeft, paths: [.top, .bottom]),
        Tile(type: .hidden, location: nil, paths: nil),
        Tile(type: .hidden, location: nil, paths: nil),
        Tile(type: .hidden, location: nil, paths: nil),
        Tile(type: .hidden, location: nil, paths: nil),
        Tile(type: .edge, location: .edgeRight, paths: [.top, .bottom])
       ],
       [Tile(type: .edge, location: .edgeLeft, paths: [.top, .bottom]),
        Tile(type: .hidden, location: nil, paths: nil),
        Tile(type: .hidden, location: nil, paths: nil),
        Tile(type: .hidden, location: nil, paths: nil),
        Tile(type: .hidden, location: nil, paths: nil),
        Tile(type: .edge, location: .edgeRight, paths: [.top, .bottom])
       ],
       [Tile(type: .edge, location: .edgeLeft, paths: [.top, .bottom]),
        Tile(type: .hidden, location: nil, paths: nil),
        Tile(type: .hidden, location: nil, paths: nil),
        Tile(type: .hidden, location: nil, paths: nil),
        Tile(type: .hidden, location: nil, paths: nil),
        Tile(type: .edge, location: .edgeRight, paths: [.top, .bottom])
       ],
       [Tile(type: .edge, location: .bottomLeftCorner, paths: [.top, .right, .topRight]),
        Tile(type: .edge, location: .edgeBottom, paths: [.left, .right]),
        Tile(type: .edge, location: .edgeBottom, paths: [.left, .right]),
        Tile(type: .edge, location: .edgeBottom, paths: [.left, .right]),
        Tile(type: .edge, location: .edgeBottom, paths: [.left, .right]),
        Tile(type: .edge, location: .bottomRightCorner, paths: [.top, .left, .topLeft])
       ],
   ]
    
    static var innerTileLayout: [[Tile]] = [
        [Tile(type: .inner, location: .diagonalTopLeft, paths: [.topLeft, .bottomRight]),
         Tile(type: .inner, location: nil, paths: nil),
         Tile(type: .inner, location: nil, paths: nil),
         Tile(type: .inner, location: nil, paths: nil),
         Tile(type: .inner, location: .diagonalTopRight, paths: [.topRight, .bottomLeft]),
        ],
        [Tile(type: .inner, location: nil, paths: nil),
         Tile(type: .inner, location: .diagonalTopLeft, paths: [.topLeft, .bottomRight]),
         Tile(type: .inner, location: nil, paths: nil),
         Tile(type: .inner, location: .diagonalTopRight, paths: [.topRight, .bottomLeft]),
         Tile(type: .inner, location: nil, paths: nil),
        ],
        [Tile(type: .inner, location: nil, paths: nil),
         Tile(type: .inner, location: nil, paths: nil),
         Tile(type: .inner, location: .center, paths: [.topRight, .topLeft, .bottomRight, .bottomLeft]),
         Tile(type: .inner, location: nil, paths: nil),
         Tile(type: .inner, location: nil, paths: nil),
        ],
        [Tile(type: .inner, location: nil, paths: nil),
         Tile(type: .inner, location: .diagonalBottomLeft, paths: [.topRight, .bottomLeft]),
         Tile(type: .inner, location: nil, paths: nil),
         Tile(type: .inner, location: .diagonalBottomRight, paths: [.topLeft, .bottomRight]),
         Tile(type: .inner, location: nil, paths: nil),
        ],
        [Tile(type: .inner, location: .diagonalBottomLeft, paths: [.topRight, .bottomLeft]),
         Tile(type: .inner, location: nil, paths: nil),
         Tile(type: .inner, location: nil, paths: nil),
         Tile(type: .inner, location: nil, paths: nil),
         Tile(type: .inner, location: .diagonalBottomRight, paths: [.topLeft, .bottomRight]),
        ],
    ]
}
