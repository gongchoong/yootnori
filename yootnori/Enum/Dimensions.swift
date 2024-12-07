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
        static let tileCount: Int = 6
        static let stageTileCount: Int = 6
        static var board: CGFloat {
            .init(Self.tileSize) * CGFloat(tileCount)
        }
        static let pieceLiftOffset: Float = 0.1
    }
    
    enum Marker {
        static let elevated: Float = 0.04
        static let dropped: Float = 0.01
        static let duration: CGFloat = 0.15
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
