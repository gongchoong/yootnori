//
//  DebugRollViewModel.swift
//  yootnori
//
//  Created by David Lee on 4/20/25.
//

import Foundation

class DebugRollViewModel: ObservableObject {
    @Published var result: [Yoot] = []
    var canRollAgain: Bool = false

    var hasRemainingRoll: Bool {
        !result.isEmpty && !canRollAgain
    }

    func roll(yoot: Yoot) async {
        canRollAgain = false
        switch yoot {
        case .yoot, .mo:
            canRollAgain = true
        default:
            break
        }

        result.append(yoot)
    }

    func discardRoll(for target: TargetNode) {
        guard let index = result.firstIndex(of: target.yootRoll) else {
            return
        }
        result.remove(at: index)
    }

}
