//
//  Dimensions.swift
//  yootnori
//
//  Created by David Lee on 9/30/24.
//

import Foundation
import SwiftUI

enum Dimensions {
    enum Board {
        static let tileSize: Float = 0.07
        static let padding: CGFloat = 0.04
        static var board: CGFloat {
            .init(Self.tileSize) * 8
            +
            (Self.padding * 2)
        }
        static let pieceLiftOffset: Float = 0.1
    }
#if os(visionOS)
    enum Screen {
        static func padding(_ physicalMetrics: PhysicalMetricsConverter) -> CGFloat {
            physicalMetrics.convert(Dimensions.Board.padding, from: .meters)
        }
        static func totalSize(_ physicalMetrics: PhysicalMetricsConverter) -> CGFloat {
            physicalMetrics.convert(Dimensions.Board.board, from: .meters)
        }
    }
#endif
}