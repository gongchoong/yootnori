//
//  GameRule.swift
//  yootnori
//
//  Created by David Lee on 10/21/24.
//

import Foundation

enum Yoot: Int, CustomStringConvertible, CaseIterable {
    case doe = 1   // 1 upside down
    case gae = 2   // 2 upside down
    case gull = 3  // 3 upside down
    case yoot = 0  // 0 upside down
    case mo = 4    // 4 upside down

    var description: String {
        switch self {
            case .doe:
                return "Doe: One step"
            case .gae:
                return "Gae: Two steps"
            case .gull:
                return "Gull: Three steps"
            case .yoot:
                return "Yoot: Four steps"
            case .mo:
                return "Mo: Five steps"
        }
    }

    var steps: Int {
        switch self {
        case .doe:
            return 1
        case .gae:
            return 2
        case .gull:
            return 3
        case .yoot:
            return 4
        case .mo:
            return 5
        }
    }

    var canThrowAgain: Bool {
        switch self {
        case .yoot, .mo:
            return true
        case .doe, .gae, .gull:
            return false
        }
    }
}
