//
//  Player.swift
//  yootnori
//
//  Created by David Lee on 7/7/25.
//
import SwiftUI

class Player: Equatable, Hashable, Codable {
    enum Constants {
        static let initialScore = 4
    }

    let name: String
    let team: Team
    var score: Int = Constants.initialScore

    private init(name: String, team: Team) {
        self.name = name
        self.team = team
    }

    static let none = Player(name: "", team: .black)
    static let playerA = Player(name: "Player A", team: .black)
    static let playerB = Player(name: "Player B", team: .white)
    static let computer = Player(name: "Compter", team: .white)

    static func == (lhs: Player, rhs: Player) -> Bool {
        lhs.team == rhs.team
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(team)
    }
}

extension Player {
    var next: Player {
        switch self {
        case .playerA:
            return .playerB
        case .playerB, .computer:
            return .playerA
        default:
            return .none
        }
    }

    var markerName: String {
        switch self {
        case .playerA:
            return "Marker_black"
        case .playerB, .computer:
            return "Marker_white"
        default:
            return ""
        }
    }

    func restart() {
        score = Constants.initialScore
    }
}

enum Team: Int, Codable, Equatable {
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
