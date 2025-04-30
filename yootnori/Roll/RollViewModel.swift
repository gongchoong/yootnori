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

    func roll() async {
        var result: Yoot
        canRollOnceMore = false
        switch Int.random(in: 1...5) {
        case 1: result = .doe
        case 2: result = .gae
        case 3: result = .gull
        case 4:
            result = .yoot
            canRollOnceMore = true
        case 5:
            result = .mo
            canRollOnceMore = true
        default:
            result = .doe
        }

        rollResult.append(result)
    }

    func discardRoll(for target: TargetNode) {
        guard let index = rollResult.firstIndex(of: target.yootRoll) else {
            return
        }
        rollResult.remove(at: index)
    }

}
