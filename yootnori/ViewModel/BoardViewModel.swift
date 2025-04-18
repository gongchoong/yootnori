//
//  BoardViewModel.swift
//  yootnori
//
//  Created by David Lee on 4/17/25.
//

import Foundation
import RealityKit

class BoardViewModel: ObservableObject {
    private var rootEntity: Entity
    private var nodeSet = Set<Node>()
    
    init(rootEntity: Entity) {
        self.rootEntity = rootEntity
        generateNodes()
    }
    
    private func generateNodes() {
        nodeSet = [
            // Outer nodes
            .topLeftVertex, .bottomLeftVertex, .topRightVertex, .bottomRightVertex,
            .topNode1, .topNode2, .topNode3, .topNode4,
            .leftNode1, .leftNode2, .leftNode3, .leftNode4,
            .rightNode1, .rightNode2, .rightNode3, .rightNode4,
            .bottomNode1, .bottomNode2, .bottomNode3, .bottomNode4,

            // Inner nodes
            .leftTopDiagonal1, .leftTopDiagonal2,
            .rightTopDiagonal1, .rightTopDiagonal2,
            .center,
            .leftBottomDiagonal1, .leftBottomDiagonal2,
            .rightBottomDiagonal1, .rightBottomDiagonal2
        ]
    }
}

extension BoardViewModel {
    func getNode(from tile: Tile) -> Node? {
        nodeSet.filter { $0.name == tile.nodeName }.first
    }
}
