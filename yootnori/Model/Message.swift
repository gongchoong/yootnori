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
    case debugRoll(_ result: Yoot, _ turn: Player)
}

struct GroupMessage: Codable {
    let id: UUID
    let sharePlayActionEvent: SharePlayActionEvent
}
