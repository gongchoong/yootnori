//
//  Constants.swift
//  yootnori
//
//  Created by David Lee on 8/24/25.
//
import Foundation
import SwiftUI

struct VertexTileViewConstants {
    var verticeInnerHeightConstant: CGFloat = 0.35
    var verticeOuterHeightConstant: CGFloat = 0.75
    var verticeOuterLineWidth: CGFloat = 7
    var edgeInnerHeightConstant: CGFloat = 0.3
    var edgeOuterHeightConstant: CGFloat = 0.5
    var edgeOuterLineWidth: CGFloat = 10
    var innerTileConstant: CGFloat = 1.25
}

struct BoardViewConstants {
    var boardColor: Color = .blue
}

struct MainViewConstants {
    var boardViewName: String = "Board"
    var yootThrowBoardName: String = "YootThrowBoard"
    var debugViewName: String = "DebugView"
    var gameStatusViewName: String = "GameStatusView"
    var rollButtonName: String = "RollButton"
    var scoreButtonName: String = "ScoreButton"
    var boardPosition: SIMD3<Float> = [0, 0, 0.3]
    var gameStatusViewPosition: SIMD3<Float> = [0, 0.38, 0.3]
    var throwBoardPosition: SIMD3<Float> = [0, -0.5, 0.25]
    var debugViewPosition: SIMD3<Float> = [0.4, 0.15, 0.3]
    var throwBoardScale: SIMD3<Float> = [0.05, 0.05, 0.05]
    var rollButtonPosition: SIMD3<Float> = [0, -0.42, 0.5]
    var scoreButtonPosition: SIMD3<Float> = [0.25, -0.33, 0.3]
}

struct YootRollManagerConstants {
    var yootEntityNames: [String] = ["yoot_1", "yoot_2", "yoot_3", "yoot_4"]
    var xOffset: Float = 0.00009
    var yOffset: Float = 0.00045
    var zOffset: Float = 0.00009
}
