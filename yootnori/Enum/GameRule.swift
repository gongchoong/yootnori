//
//  GameRule.swift
//  yootnori
//
//  Created by David Lee on 10/21/24.
//

import Foundation

enum Yoot: CustomStringConvertible {
    case doe(steps: Int = 1)
    case gae(steps: Int = 2)
    case gull(steps: Int = 3)
    case yoot(steps: Int = 4)
    case mo(steps: Int = 5)

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
}
