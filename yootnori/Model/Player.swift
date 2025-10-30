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
    var score: Int = 4

    private init(name: String, team: Team) {
        self.name = name
        self.team = team
    }

    static let none = Player(name: "", team: .black)
    static let playerA = Player(name: "Player A", team: .black)
    static let playerB = Player(name: "Player B", team: .white)

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

    var markerName: String {
        switch self {
        case .playerA:
            return "Marker_black"
        case .playerB:
            return "Marker_white"
        default:
            return ""
        }
    }
}

enum Team: Int {
    case black
    case white

    var color: Color {
        switch self {
        case .black:
            return .white
        case .white:
            return .black
        }
    }

    var name: String {
        switch self {
        case .black:
            return "Black"
        case .white:
            return "White"
        }
    }
}
