//
//  GameRule.swift
//  yootnori
//
//  Created by David Lee on 10/21/24.
//

import Foundation

enum Yoot: CustomStringConvertible {
    case doe
    case gae
    case gull
    case yoot
    case mo

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
}
