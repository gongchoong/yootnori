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
        static let tileSize: Float = 0.1
        static let tileCount: Int = 6
        static let stageTileCount: Int = 6
        static var board: CGFloat {
            .init(Self.tileSize) * CGFloat(tileCount)
        }
        static let pieceLiftOffset: Float = 0.1
        static let depthConstant: CGFloat = 1.5
    }
    
    enum Marker {
        static let elevated: Float = 0.04
        static let dropped: Float = 0.01
        static let duration: CGFloat = 0.15
    }
#if os(visionOS)
    enum Screen {
        static func totalSize(_ physicalMetrics: PhysicalMetricsConverter) -> CGFloat {
            let size = physicalMetrics.convert(Dimensions.Board.board, from: .meters)
            print("size = \(size)")
            return size
        }

        static func depth(_ physicalMetrics: PhysicalMetricsConverter) -> CGFloat {
            let depth = physicalMetrics.convert(Dimensions.Board.board * Dimensions.Board.depthConstant, from: .meters)
            print("depth = \(depth)")
            return depth
        }
    }
#endif
}
