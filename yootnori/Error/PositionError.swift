//
//  PositionError.swift
//  yootnori
//
//  Created by David Lee on 10/12/24.
//

import Foundation

enum PositionError: Error {
    case outerTileOutOfRange(Int, Int)
    case innerTileOutOfRange(Int, Int)
    case stageTileOutOfRange(Int, Int)
}

extension PositionError: LocalizedError {
    var errorDescription: String? {
            switch self {
            case .outerTileOutOfRange(let column, let row):
                return "outerTileOutOfRange (\(column), \(row))"
            case .innerTileOutOfRange(let column, let row):
                return "innerTileOutOfRange (\(column), \(row))"
            case .stageTileOutOfRange(let column, let row):
                return "stageTileOutOfRange (\(column), \(row))"
            }
        }
}
