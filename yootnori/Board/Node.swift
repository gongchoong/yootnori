//
//  Node.swift
//  yootnori
//
//  Created by David Lee on 11/2/24.
//

import Foundation

struct Node {
    let type: NodeType
    let next: [NodeType]
    let prev: [NodeType]
}

extension Node {
    static var empty: Self {
        Node(type: .empty, next: [], prev: [])
    }

    static var topLeftVertex: Self {
        Node(
            type: .topLeftVertex,
            next: [.leftNode1, .leftTopDiagonal1],
            prev: [.topNode4]
        )
    }

    static var topNode4: Self {
        Node(
            type: .topNode4,
            next: [.topLeftVertex],
            prev: [.topNode3]
        )
    }
}
