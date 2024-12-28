//
//  MarkerManager.swift
//  yootnori
//
//  Created by David Lee on 12/28/24.
//

import Foundation
import RealityKit

class MarkerManager {
    private var markerMap: [Node: Entity?] = [:]
}

extension MarkerManager {
    func create(marker: Entity, node: Node) {
        markerMap[node] = marker
    }

    func remove(node: Node) {
        markerMap[node] = nil
    }

    func update(marker: Entity, node: Node) {
        guard let previousNode = markerMap.first(where: { $0.value == marker })?.key else { return }
        markerMap[previousNode] = nil
        markerMap[node] = marker
    }

    func getNode(from entity: Entity) -> Node? {
        return markerMap.first(where: {
            $0.value == entity
        })?.key
    }

    func printMap() {
        let map = markerMap.filter { $0.value != nil }
        for item in map.keys {
            print(item.name)
        }
    }
}
