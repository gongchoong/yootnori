//
//  RollViewModel.swift
//  yootnori
//
//  Created by David Lee on 4/20/25.
//

import Foundation

class RollViewModel: ObservableObject {
    @Published var rollResult: [Yoot] = []
    var canRollOnceMore: Bool = false

    var hasRemainingRoll: Bool {
        !rollResult.isEmpty && !canRollOnceMore
    }

    var yootRollSteps: [String] {
        return rollResult.map { "\($0.steps)" }
    }

    func roll(yoot: Yoot) async {
        canRollOnceMore = false
        switch yoot {
        case .yoot, .mo:
            canRollOnceMore = true
        default:
            break
        }

        rollResult.append(yoot)
    }

    func discardRoll(for target: TargetNode) {
        guard let index = rollResult.firstIndex(of: target.yootRoll) else {
            return
        }
        rollResult.remove(at: index)
    }

}
