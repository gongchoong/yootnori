//
//  Message.swift
//  yootnori
//
//  Created by David Lee on 9/27/25.
//

import Foundation

enum SharePlayActionEvent: Codable {
    case assignPlayer(_ seed: UInt64)
    case established
    case startGame
    case newMarkerButtonTap
    case debugRoll(_ result: Yoot)
    case tapTile(_ tile: Tile)
    case tapMarker(on: Node)
}

struct GroupMessage: Codable {
    let id: UUID
    let sharePlayActionEvent: SharePlayActionEvent
}
