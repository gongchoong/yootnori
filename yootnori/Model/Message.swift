//
//  Message.swift
//  yootnori
//
//  Created by David Lee on 9/27/25.
//

import Foundation

enum TempActionEvent: Codable {
    case assignPlayer(_ seed: UInt64)
}

struct GroupMessage: Codable {
    let id: UUID
    let message: String
    let tempActionEvent: TempActionEvent
}
