//
//  NodeDetails.swift
//  yootnori
//
//  Created by David Lee on 11/2/24.
//

import Foundation

struct Node: Hashable {
    let name: NodeName
    let index: Index
}

struct TargetNode: Hashable {
    let name: NodeName
    let yootRoll: Yoot
}
