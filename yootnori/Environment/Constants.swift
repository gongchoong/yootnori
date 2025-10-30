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
    var boardPosition: SIMD3<Float> = [-0.1, 0.15, -0.1]
    var debugViewPosition: SIMD3<Float> = [0.3, 0.15, -0.1]
    var gameStatusViewPosition: SIMD3<Float> = [0.3, 0, -0.1]
    var throwBoardPosition: SIMD3<Float> = [0, -0.5, -0.2]
    var throwBoardScale: SIMD3<Float> = [0.05, 0.05, 0.05]
    var rollButtonPosition: SIMD3<Float> = [0, -0.4, 0.4]
    var scoreButtonPosition: SIMD3<Float> = [0.15, -0.34, -0.1]
}

struct YootRollManagerConstants {
    var yootEntityNames: [String] = ["yoot_1", "yoot_2", "yoot_3", "yoot_4"]
    var xOffset: Float = 0.00009
    var yOffset: Float = 0.00045
    var zOffset: Float = 0.00009
}
