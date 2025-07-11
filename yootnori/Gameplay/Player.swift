//
//  Player.swift
//  yootnori
//
//  Created by David Lee on 7/7/25.
//
import SwiftUI

class Player: Equatable, Hashable {
    let name: String
    let team: Team
    var score: Int = 0

    private init(name: String, team: Team) {
        self.name = name
        self.team = team
    }

    static let none = Player(name: "", team: .none)
    static let playerA = Player(name: "Player A", team: .a)
    static let playerB = Player(name: "Player B", team: .b)

    static func == (lhs: Player, rhs: Player) -> Bool {
        lhs.team == rhs.team
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(team)
    }
}

extension Player {
    var opponent: Player {
        switch self {
        case .playerA:
            return .playerB
        case .playerB:
            return .playerA
        default:
            return .none
        }
    }
}

enum Team: String {
    case a
    case b
    case none

    var color: Color {
        switch self {
        case .a:
            return .white
        case .b:
            return .black
        case .none:
            return .red
        }
    }
}
